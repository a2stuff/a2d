--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl7 cffa2 -debug -debugger none"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--

--[[
  Notes:

  '-debug' enables the debugger
  '-debugger none' doesn't show an actual debugger window, really runs

  Useful links:

  - https://www.mamecheat.co.uk/forums/viewtopic.php?t=13285
  -- covers issues with bpset/wpset

  - https://www.reddit.com/r/MAME/comments/9n93sw/mame_lua_help_noticing_a_specific_pc_in_the_code/
  -- discussion about this very issue

  - https://github.com/mamedev/mame/blob/master/plugins/cheat/init.lua#L267
  -- pointed to by above - real code that works


  - https://github.com/mamedev/mame/issues/2451#issuecomment-317299876
  -- "The none debugger can't be used with the lua console for breakpoints because it will always immediately resume when stopped. Non-interactive scripts should be okay because emu.register_periodic is always called."
  -- More precisely, the breakpoint doesn't stop; you can still tell that it was hit, which is enough for applications such as determining that control has returned to an idle loop, etc.

]]--

--[[
local debugger = manager.machine.debugger
local cpu = manager.machine.devices[":maincpu"]

local mem = cpu.spaces["program"] -- only needed for watchpoints
-- TODO: aux memory on IIe?

-- print("setting watchpoint")
-- cpu.debug:wpset(mem, "rw", 0x4000, 1, '1', 'printf "Read @ %08X\n",wpaddr ; g')

-- TODO: Build abstraction allowing registering a BP/WP callback
-- TODO: ... and ensure it handles banking configuration

local MAIN_LOOP1 = 0x4054 -- main event input loop
local MAIN_LOOP2 = 0x405A -- tight loop if no event

local id = cpu.debug:bpset(MAIN_LOOP1, '1', '') -- all arguments are required or we crash!
--bp = cpu.debug:bplist()[id] -- example

-- TODO: Add WP for tick_counter (4105...4107)
--id = cpu.debug:wpset(mem, "rw", 0x4106, 1, '1', 'g') -- makes everything stall?
--id = cpu.debug:wpset(mem, "rw", 0x4106, 1, '1', '') -- crashes
--id = cpu.debug:wpset(mem, "rw", 0x4106, 1) -- crashes w/o args
--wp = cpu.debug:wplist()[id] -- example

function describe_bp(bp)
  print("bp index: " .. bp.index)
  print(" enabled: " .. (bp.enabled and "yes" or "no"))
  print("    addr: " .. string.format("%04X", bp.address))
  print("    cond: " .. bp.condition)
  print("  action: " .. bp.action)
end

function describe_wp(wp)
  print("wp index: " .. wp.index)
  print(" enabled: " .. (wp.enabled and "yes" or "no"))
  print("    type: " .. wp.type)
  print("    addr: " .. string.format("%04X", bp.address))
  print("     len: " .. wp.length)
  print("    cond: " .. wp.condition)
  print("  action: " .. wp.action)
end

function describe_cpu()
  print("CPU")
  print("  PC: " .. string.format("%04X", cpu.state.PC.value))
  print("   A: " .. string.format("%02X", cpu.state.A.value))
  print("   X: " .. string.format("%02X", cpu.state.X.value))
  print("   Y: " .. string.format("%02X", cpu.state.Y.value))
  -- TODO: Cycle count? Use emulation time as a proxy
  print("  time: " .. manager.machine.time.usec .. "usec")

  print("MMU")
  print(" RDRAMRD: " .. ((apple2.ReadSSW("RDRAMRD")>127) and "on" or "off"))
end



-- Register callback, called when a frame is drawn or there's a debug break

local count = 0

local last = 0
local consolelog = debugger.consolelog -- alias
emu.register_periodic(function()
    if #consolelog == last then
      return
    end

    last = #consolelog
    local msg = consolelog[#consolelog]
    if msg:find("Stopped at", 1, true) then
      last = #consolelog

      -- Ignore aux for now
      if apple2.ReadSSW("RDRAMRD") > 127 then
        return
      end

      print("")
      print("------------------------------")


      describe_cpu()

      local index
      index = tonumber(msg:match("Stopped at breakpoint ([0-9]+)"))
      if index then
        print("stopped at bp")
        local bp = cpu.debug:bplist()[index]
        describe_bp(bp)


        local ticks = apple2.ReadRAMDevice(0x4105) +
          (apple2.ReadRAMDevice(0x4106)<<8) +
          (apple2.ReadRAMDevice(0x4107)<<16)
        print(" >>> ticks " .. ticks)
        count = count+1
        print(" >>> count " .. count)
        if count > 4 then
          print "disabling bp after 10"
          cpu.debug:bpdisable(index)
        end

        -- If "-debugger none" is used, this is unnecessary.
        debugger.execution_state = "run"
        return
      end

      index = tonumber(msg:match("Stopped at watchpoint ([0-9]+)"))
      if index then
        print("stopped at wp")
        local wp = cpu.debug:wplist()[index]
        describe_wp(wp)

        -- If "-debugger none" is used, this is unnecessary.
        debugger.execution_state = "run"
        return
      end

      print("unknown message: " .. msg)
    else
      print("ignoring '"..msg)
    end
end)


-- TODO: What to do here?
emu.wait(60)

]]--

--[[

  This is from a non-mainline branch, apparently:

  https://github.com/mamedev/mame/issues/2451


function callback1()
  print("callback1 ran")
end

function callback2()
  print("callback2 ran")
end

cpu = manager.machine.devices[":maincpu"]
cpu:break_set(0x4000, callback1)
cpu:break_set(0x2000, callback2)

]]--

-- Still requires '-debug -debugger none` so not sure if we want this

-- bank is "main" or "aux"
local pc_waiter_bank = nil
local pc_waiter_id = nil
local pc_waiter_signal = nil
function WaitForPC(address, bank)
  local cpu = manager.machine.devices[":maincpu"]
  pc_waiter_id = cpu.debug:bpset(address, '1', '')
  pc_waiter_bank = bank
  pc_waiter_signal = nil
  repeat
    emu.wait(1/60)
  until pc_waiter_signal
end

function CurrentBank()
end
do
  local cpu = manager.machine.devices[":maincpu"]
  local consolelog = manager.machine.debugger.consolelog -- alias
  local last = 0
  emu.register_periodic(function()
      if #consolelog == last then
        return
      end
      last = #consolelog
      local index = tonumber(consolelog[#consolelog]:match("Stopped at breakpoint ([0-9]+)"))
      if index then
        local bank = (apple2.ReadSSW("RDRAMRD") > 127) and "aux" or "main"
        if index == pc_waiter_id and bank == pc_waiter_bank then
          cpu.debug:bpclear(pc_waiter_id)
          pc_waiter_id = nil
          pc_waiter_bank = nil
          pc_waiter_signal = true
        end
      end
  end)
end

print("waiting...")
WaitForPC(0x405A, "main")
print("done!")

print("waiting...")
WaitForPC(0x51B2, "main")
print("done!")
