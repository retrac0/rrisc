{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE RecordWildCards #-}

-- | CPU core (sim.py @CPU@).
module RRISC.Sim.CPU (
  CPU (..),
  CpuScalars (..),
  MaxCycleErr (..),
  newCPU,
  wrReg,
  rdReg,
  rdMem,
  wrMem,
  randomizeCPU,
  loadMem,
  stepCPU,
  showState,
) where

import Control.Exception (Exception, throwIO)
import Control.Monad (when)
import Data.Bits ((.&.), shiftL, shiftR, (.|.))
import Data.IORef (
  IORef,
  modifyIORef',
  newIORef,
  readIORef,
 )
import Data.Word (Word16)
import qualified Data.Vector.Mutable as MV
import System.Random (randomRIO)
import Text.Printf (printf)

import RRISC.Disasm (branchOffset, disasmWord)
import RRISC.ISA (
  addOp,
  addcOp,
  addiOp,
  andOp,
  imm6Mask,
  luiOp,
  specOp,
  subOp,
  subiOp,
  jalrRb,
  lwrRb,
  rolRb,
  rorRb,
  swrRb,
  wordMask,
 )
import RRISC.Sim.Bus (Bus, busRead, busWrite, newBus)
import RRISC.Sim.Memory (
  BankKind (..),
  BankRecord (..),
  defaultBankSpecs,
  loadPackedBinaryIntoBanks,
  memorySystemFromSpecs,
 )

data MaxCycleErr = MaxCycleErr !Int
  deriving (Show)

instance Exception MaxCycleErr

-- | Scalar machine state packed for fewer IORef touches per step.
data CpuScalars = CpuScalars
  { csT :: !Int
  , csPc :: !Int
  , csRunning :: !Bool
  , csTrace :: !Bool
  , csInstrRetired :: !Integer
  , csCycles :: !Integer
  , csUartYield :: !Bool
  , csMaxCycles :: !Int
  }

data CPU = CPU
  { cRegs :: !(MV.IOVector Word16)
  , cScalars :: !(IORef CpuScalars)
  , -- | Same backing store as the lone RAM bank when 'newCPU' enables the fast path.
    cFastRam :: !(Maybe (MV.IOVector Word16))
  , cBus :: !Bus
  , cBanks :: ![BankRecord]
  }

initialScalars :: CpuScalars
initialScalars =
  CpuScalars
    { csT = 0
    , csPc = 0
    , csRunning = True
    , csTrace = False
    , csInstrRetired = 0
    , csCycles = 0
    , csUartYield = False
    , csMaxCycles = 0
    }

-- | Single bank RAM @0..0o7770@ with no other banks — enables direct vector loads/stores (unless bus trace is on; see 'newCPU').
fastRamEligible :: [(BankKind, Int, Int)] -> Bool
fastRamEligible specs =
  case specs of
    [(BankRam, base, sz)] -> (base .&. wordMask) == 0 && sz == 0o7770
    _ -> False

newCPU :: [(BankKind, Int, Int)] -> Bool -> IO CPU
newCPU specs0 allowFastRam = do
  let specs = if null specs0 then defaultBankSpecs else specs0
  bus <- newBus
  banks <- memorySystemFromSpecs bus specs
  regs <- MV.new 8
  MV.set regs 0
  MV.write regs 0 0
  MV.write regs 7 (fromIntegral wordMask)
  let fr =
        if allowFastRam && fastRamEligible specs
          then case banks of
            [BankRecord BankRam _ _ (Just v)] -> Just v
            _ -> Nothing
          else Nothing
  scalars <- newIORef initialScalars
  CPU regs scalars fr <$> pure bus <*> pure banks

{-# INLINE modifyScalars #-}
modifyScalars :: CPU -> (CpuScalars -> CpuScalars) -> IO ()
modifyScalars cpu f = modifyIORef' (cScalars cpu) f

{-# INLINE readScalars #-}
readScalars :: CPU -> IO CpuScalars
readScalars cpu = readIORef (cScalars cpu)

wrReg :: CPU -> Int -> Int -> IO ()
wrReg cpu rd val =
  when (rd /= 0 && rd /= 7) $
    MV.write (cRegs cpu) rd (fromIntegral (val .&. wordMask))

rdReg :: CPU -> Int -> IO Int
rdReg cpu rs = fromIntegral <$> MV.read (cRegs cpu) rs

{-# INLINE rdMem #-}
rdMem :: CPU -> Int -> IO Int
rdMem cpu addr0 =
  let addr = addr0 .&. wordMask
   in case cFastRam cpu of
        Just vec | addr < 0o7770 ->
          fromIntegral <$> MV.read vec addr
        _ ->
          busRead (cBus cpu) addr

{-# INLINE wrMem #-}
wrMem :: CPU -> Int -> Int -> IO ()
wrMem cpu addr0 val0 =
  let addr = addr0 .&. wordMask
      val = val0 .&. wordMask
   in case cFastRam cpu of
        Just vec | addr < 0o7770 ->
          MV.write vec addr (fromIntegral val)
        _ ->
          busWrite (cBus cpu) addr val

randomizeCPU :: CPU -> IO ()
randomizeCPU cpu = do
  mapM_ randomizeBank (cBanks cpu)
  mapM_
    ( \i -> do
        v <- randomRIO (0, wordMask)
        MV.write (cRegs cpu) i (fromIntegral v)
    )
    [1 .. 6]
  t <- randomRIO (0, 1 :: Int)
  modifyScalars cpu $ \s -> s {csT = t}
 where
  randomizeBank br =
    case (brKind br, brVec br) of
      (BankRam, Just vec) ->
        mapM_
          ( \j -> do
              v <- randomRIO (0, wordMask)
              MV.write vec j (fromIntegral v)
          )
          [0 .. brSize br - 1]
      _ -> pure ()

loadMem :: CPU -> FilePath -> IO ()
loadMem cpu path = loadPackedBinaryIntoBanks path 0 (cBanks cpu)

showState :: CPU -> IO String
showState cpu = do
  CpuScalars {csT = t, csPc = pc, csInstrRetired = ir, csCycles = cy} <- readScalars cpu
  rs <- mapM (rdReg cpu) [0 .. 7]
  let regStr =
        concat
          [ printf "r%d: %04o " i v :: String
          | (i, v) <- zip [(0 :: Int) .. 7] rs
          ]
  pure $
    printf "T: %d PC: %04o %s\n" t pc regStr
      ++ printf "Instructions retired: %d (%d cycles)\n" ir cy

-- | Trace annotation matching sim.py (derived from post-execution state).
traceNote :: CPU -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> IO String
traceNote cpu oldpc ir op rd _ra rb _imm = do
  CpuScalars {csPc = pc, csT = t} <- readScalars cpu
  let nextPc = (oldpc + 1) .&. wordMask
  pure $
    if
      | ir == 0o7777 -> ""
      | op == specOp && rb == lwrRb -> "+2cyc"
      | op == specOp && rb == swrRb -> "+2cyc"
      | op == luiOp && (rd == 0 || rd == 7) ->
          if pc /= nextPc then printf "-> %04o" pc else "not taken"
      | op == addiOp && (rd == 0 || rd == 7) ->
          if pc /= nextPc then printf "-> %04o" pc else "not taken"
      | op == specOp && rb == jalrRb -> printf "-> %04o" pc
      | op == subOp || op == addOp || op == addcOp || op == subiOp ->
          "T=" ++ show t
      | op == specOp && rb == rorRb -> printf "T=%d" t
      | op == specOp && rb == rolRb -> printf "T=%d" t
      | op == andOp -> ""
      | op == luiOp -> ""
      | op == addiOp -> ""
      | otherwise -> "unknown"

{-# INLINE executeInsn #-}
-- | Run opcode effects; returns whether this instruction counts as a memory op for cycle accounting.
executeInsn :: CPU -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> IO Bool
executeInsn cpu oldpc ir op rd ra rb imm =
  if
    | op == andOp -> do
        a <- rdReg cpu ra
        b <- rdReg cpu rb
        wrReg cpu rd (a .&. b)
        pure False
    | op == subOp -> do
        a <- rdReg cpu ra
        b <- rdReg cpu rb
        let val = a - b
        wrReg cpu rd val
        let t' = if (val .&. 0o10000) /= 0 then 1 else 0
        modifyScalars cpu $ \s -> s {csT = t'}
        pure False
    | op == addOp -> do
        a <- rdReg cpu ra
        b <- rdReg cpu rb
        let val = a + b
        wrReg cpu rd val
        let t' = if val > wordMask then 1 else 0
        modifyScalars cpu $ \s -> s {csT = t'}
        pure False
    | op == addcOp -> do
        a <- rdReg cpu ra
        b <- rdReg cpu rb
        t0 <- csT <$> readScalars cpu
        let val = a + b + t0
        wrReg cpu rd val
        let t' = if val > wordMask then 1 else 0
        modifyScalars cpu $ \s -> s {csT = t'}
        pure False
    | op == luiOp && (rd == 0 || rd == 7) -> do
        t0 <- csT <$> readScalars cpu
        if t0 == 0
          then
            modifyScalars cpu $ \s ->
              s {csPc = (oldpc + branchOffset rd imm) .&. wordMask}
          else pure ()
        pure False
    | op == addiOp && (rd == 0 || rd == 7) -> do
        t0 <- csT <$> readScalars cpu
        if t0 /= 0
          then
            modifyScalars cpu $ \s ->
              s {csPc = (oldpc + branchOffset rd imm) .&. wordMask}
          else pure ()
        pure False
    | op == luiOp -> wrReg cpu rd (imm `shiftL` 6) >> pure False
    | op == addiOp -> do
        cur <- rdReg cpu rd
        wrReg cpu rd (cur + imm)
        pure False
    | op == subiOp -> do
        cur <- rdReg cpu rd
        let val = cur - imm
        wrReg cpu rd val
        let t' = if (val .&. 0o10000) /= 0 then 1 else 0
        modifyScalars cpu $ \s -> s {csT = t'}
        pure False
    | op == specOp && rb == jalrRb -> do
        target <- rdReg cpu ra
        pcAfter <- csPc <$> readScalars cpu
        wrReg cpu rd pcAfter
        modifyScalars cpu $ \s -> s {csPc = target .&. wordMask}
        pure False
    | op == specOp && rb == rorRb -> do
        val <- rdReg cpu ra
        t0 <- csT <$> readScalars cpu
        let newT = val .&. 1
            val' = (val `shiftR` 1) .|. (t0 `shiftL` 11)
        modifyScalars cpu $ \s -> s {csT = newT}
        wrReg cpu rd val'
        pure False
    | op == specOp && rb == rolRb -> do
        val <- rdReg cpu ra
        t0 <- csT <$> readScalars cpu
        let newT = (val `shiftR` 11) .&. 1
            val' = ((val `shiftL` 1) .&. wordMask) .|. t0
        modifyScalars cpu $ \s -> s {csT = newT}
        wrReg cpu rd val'
        pure False
    | op == specOp && rb == lwrRb -> do
        addr <- rdReg cpu ra
        v <- rdMem cpu addr
        wrReg cpu rd v
        pure True
    | op == specOp && rb == swrRb -> do
        addr <- rdReg cpu ra
        dat <- rdReg cpu rd
        wrMem cpu addr dat
        pure True
    | ir == 0o7777 -> do
        modifyScalars cpu $ \s -> s {csRunning = False}
        pure False
    | otherwise -> pure False

stepCPU :: CPU -> IO ()
stepCPU cpu = do
  s0 <- readScalars cpu
  let tr = csTrace s0
      oldpc = csPc s0
  ir <- rdMem cpu oldpc
  modifyScalars cpu $ \s -> s {csPc = (csPc s + 1) .&. wordMask}
  let op = (ir `shiftR` 9) .&. 7
      rd = (ir `shiftR` 6) .&. 7
      ra = (ir `shiftR` 3) .&. 7
      rb = ir .&. 7
      imm = ir .&. imm6Mask
  isMem <- executeInsn cpu oldpc ir op rd ra rb imm
  when tr $ do
    note <- traceNote cpu oldpc ir op rd ra rb imm
    let line = printf "%04o  %04o  %-20s  %s" oldpc ir (disasmWord ir) note
    putStrLn $ reverse . dropWhile (== ' ') $ reverse line
  modifyScalars cpu $ \s ->
    s
      { csInstrRetired = csInstrRetired s + 1
      , csCycles = csCycles s + if isMem then 2 else 1
      }
  CpuScalars {csMaxCycles = mc, csCycles = cy} <- readScalars cpu
  when (mc > 0 && fromIntegral mc <= cy) $
    throwIO (MaxCycleErr mc)
