os.execute("clear")
core.console('clear')
local DEBUG = true
-------------------------------------------------------------------------------------------------------------
-- USAGE:
-------------------------------------------------------------------------------------------------------------
-- Run me like this (connected via USB): ./pm3 -l ntag_bruteforce.lua
-- Run me like this (connected via Blueshark addon): ./client/proxmark3 /dev/rfcomm0 -l ./ntag_bruteforce.lua
-------------------------------------------------------------------------------------------------------------
-- VER  | AUTHOR         | DATE         | CHANGE
-------------------------------------------------------------------------------------------------------------
-- 1.0  | Keld Norman,   | 30 okt. 2021 | Initial version
-- 1.1  | Keld Norman,   | 30 okt. 2021 | Added: Press enter to stop the script
-------------------------------------------------------------------------------------------------------------
-- TODO:
-------------------------------------------------------------------------------------------------------------
-- Will never be done but i will write them down here anyway..
-- Output file not implemented yet
-- Check for no combination of both -i and -s -e
-- Add  -c continue from last card or password used
-------------------------------------------------------------------------------------------------------------
-- PASSWORD LISTS: 
-------------------------------------------------------------------------------------------------------------
-- Crunch can generate all (14.776.336) combinations of 4 chars with a-z + A-Z + 0-9 like this: 
--
-- crunch 4 4 "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" -o keys/4_chars_and_digits.list
-- 
-- for LINE in $(cat keys/4_chars_and_digits.list) ; do echo -n ${LINE} |xxd -p -u;done > keys/4_chars_and_digits_hex.list
--
-------------------------------------------------------------------------------------------------------------
-- Required includes
-------------------------------------------------------------------------------------------------------------
local getopt = require('getopt')
local ansicolors  = require('ansicolors')
-------------------------------------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------------------------------------
local command = ''
local option, argument
local bruteforce = true
local password_is_ascii = true
local pass_text = "Passwords in file is treated as: ASCII"
local bruteforce_status_file = 'ntag_status.txt'
-------------------------------------------------------------------------------------------------------------
copyright = ''
script    = 'Script      : ntag_bruteforce.lua'
author    = 'Author      : Keld Norman'
version   = 'Version     : 1.0.0'
-------------------------------------------------------------------------------------------------------------
desc      = [[Description : Bruteforces 7 byte UID NTAG protected with a 32 bit password

      .-.
     /   \         .-.
    /     \       /   \       .-.     .-.     _   _
+--/-------\-----/-----\-----/---\---/---\---/-\-/-\/\/---
  /         \   /       \   /     '-'     '-'
 /           '-'         '-'
 ]]
-------------------------------------------------------------------------------------------------------------
example   = [[

Example of how to run the script with bruteforcing of continuously HEX numbers with 1 secound delay between tests:

 script run ntag_bruteforce -s 00000000 -e FFFFFFFF -t 1000  -o /var/log/ntag_bruteforce.log 

Example of how to run the script and bruteforc the card using passwords from the input file with 1s delay between tests

 script run ntag_bruteforce -i /home/my_4_char_passwords_list.txt -o /var/log/ntag_bruteforce.log ]]
-------------------------------------------------------------------------------------------------------------
usage      = [[

script run ntag_bruteforce [-s <start_id>] [-e <end_id>] [-t <timeout>] [ -o <output_file> ] [ -h for help ]
script run ntag_bruteforce [-i <input_file>] [-t <timeout>] [ -o <output_file> ] [ -h for help ]

DESCRIPTION 

This script will test either an 8 digit hexadecimal code or 4 char stings (will be converted to an 8 digit hex string )
against NFC cards of the type NTAG21x protected by a 32 bit password.

Read more about NTAGs here: https://www.nxp.com/docs/en/data-sheet/NTAG213_215_216.pdf
]]
-------------------------------------------------------------------------------------------------------------
arguments   = [[

    -i       input_file           Read 4 char ASCII values to test from this file (will override -s and -e )
    -x                            Password file (-i) contains HEX values (4 x 2hex -> 32 bit/line)
    -o       output_file          Write output to this file
    -s       0-0xFFFFFFFF         start id
    -e       0-0xFFFFFFFF         end id
    -t       0-99999, pause       timeout (ms) between cards 1000 = 1 second
                                  (use the word 'pause' to wait for user input)
    -h       this help
]]
-------------------------------------------------------------------------------------------------------------
-- FUNCTIONS
-------------------------------------------------------------------------------------------------------------
-- Check availability of file
local function file_check(file_name)
 local exists = io.open(file_name, "r")
 if not exists then
  exists = false
 else
  exists = true
 end
 return exists
end
-- read lines from a file
function read_lines_from(file)
 print(ansicolors.yellow..'\nPlease wait while loading password file..'..ansicolors.reset)
 readlines = {}
 for line in io.lines(file) do 
  readlines[#readlines + 1] = line
 end
 return readlines
end
-- write to file
function writeOutputBytes(bytes, outfile)
 local fileout,err = io.open(outfile, "wb")
 if err then 
  print("### ERROR - Faild to open output-file ".. outfile)
  return false
 end
 for i = 1, #bytes do
  fileout:write(string.char(tonumber(bytes[i], 16)))
 end
 fileout:close()
 print("\nwrote " .. #bytes .. " bytes to " .. outfile)
 return true
end
-- find number of entrys in a table
function tablelength(table)
 local count = 0
 for _ in pairs(table) do count = count + 1 end
 return count
end
-- debug print function
local function dbg(args)
    if not DEBUG then return end
    if type(args) == 'table' then
        local i = 1
        while result[i] do
            dbg(result[i])
            i = i+1
        end
    else
        print('###', args)
    end
end
-- when errors occur
local function oops(err)
 print(ansicolors.red..'\n### ERROR - '.. err ..ansicolors.reset)
 core.clearCommandBuffer()
 return nil, err
end
-- Usage help
local function help()
 print(copyright)
 print(script)
 print(author)
 print(version)
 print(desc)
 print(ansicolors.cyan..'Usage'..ansicolors.reset)
 print(usage)
 print(ansicolors.cyan..'Arguments'..ansicolors.reset)
 print(arguments)
 print(ansicolors.cyan..'Example usage'..ansicolors.reset)
 print(example)
end
--- Print user message
local function msg(msg)
 print( string.rep('--',20) )
 print('')
 print(msg)
 print('')
 print( string.rep('--',20) )
end
-- Convert a string in to a hex string
function convert_string_to_hex(str)
 return (
  str:gsub('.', function (c)
    return string.format('%02X', string.byte(c))
   end
  )
 )
end
-- Check if string is 4 chars ascii (32 bit) = 8 chars hex
function check_if_string_is_hex(value)
 local patt = "%x%x%x%x%x%x%x%x"
 if string.find(value, patt) then
  return true
 else
  return false
 end
end
-------------------------------------------------------------------------------------------------------------
-- MAIN FUNCTION
-------------------------------------------------------------------------------------------------------------
local function main(args)
 local i = 0
 local bytes = {}
 local start_id = 0
 local end_id = 0xFFFFFFFF
 local timeout = 0
 local infile, outfile
 -- stop if no args is given
 if #args == 0 then
  print(ansicolors.red..'\n### ERROR - Missing parameters'..ansicolors.reset)
  help()
  return
 end
-------------------------------------------------------------------------------------------------------------
-- Get arguments
-------------------------------------------------------------------------------------------------------------
 for option, argument in getopt.getopt(args, ':s:e:t:i:o:xh') do
  -- error in options
  if optind == '?' then
   return print('unrecognized option', args[optind -1])
  end
  -- no options
  if option == '' then
   return help()
  end
  -- start hex value
  if option == 's' then 
   start_id = argument
  end
  -- end hex value
  if option == 'e' then 
   end_id = argument
  end
  -- timeout
  if option == 't' then 
   timeout = argument
  end
  -- input file
  if option == 'i' then 
   infile = argument
   if (file_check(infile) == false) then 
    return oops('input file: '..infile..' not found') 
   end
   bruteforce = false
  end
  -- passwordlist is hex values
  if option == 'x' then 
   password_is_ascii = false 
   pass_text = "Passwords in file is treated as: HEX"
  end
  -- output file
  if option == 'o' then
   outfile = argument
   if (file_check(argument)) then
    local answer = utils.confirm('\nthe output-file '..argument..' already exists!\nthis will delete the previous content!\ncontinue?')
    if (answer == false) then 
     return oops('quiting') 
    end
   end
  end
  -- help
  if option == 'h' then 
   return help()
  end
 end
 -- min timeout is set to 1 sec if it is empty
 if timeout == 0 then 
  timeout = 1000 
 end 
-------------------------------------------------------------------------------------------------------------
-- BRUTEFORCE
-------------------------------------------------------------------------------------------------------------
 -- select bruteforce method
 if bruteforce then
  -----------------------------------------------------
  -- START BRUTEFORCE WITH CONTINUOUSLY HEX NUMBERS  --
  -----------------------------------------------------
  command = 'hf mfu i -k %08X'
  msg('Bruteforcing NTAG Passwords\n\nStart value: ' .. start_id .. '\nStop value : ' .. end_id ..'\nDelay between tests: '..timeout..' ms')
  for n = start_id, end_id do
   -- abort if key is pressed
   if core.kbd_enter_pressed() then
    print("aborted by user")
    break
   end
   local c = string.format( command, n )
   core.console(c)
   print('[=] Tested password ' .. ansicolors.yellow .. ansicolors.bright .. string.format("%08X",n) .. ansicolors.reset) 
  --  print('[+] Passwords left to try: '..ansicolors.green..ansicolors.bright..passwords_left_to_try .. ansicolors.reset..' of '..ansicolors.green..ansicolors.bright..count_lines..ansicolors.reset)
   print('[=] Ran command: "'..c..'"')
   print('[=] -------------------------------------------------------------')
   core.console('msleep -t'..timeout);
   core.console('hw ping')
   print('[=] -------------------------------------------------------------')
  end
  -----------------------------------------------------
  -- END BRUTEFORCE WITH CONTINUOUSLY HEX NUMBERS    --
  -----------------------------------------------------
 else
  -----------------------------------------------------
  -- START BRUTEFORCE WITH PASSWORDS FROM A FILE    --
  -----------------------------------------------------
  local counter = 1
  local password
  local passwords_left_to_try
  local lines = read_lines_from(infile)
  local count_lines = tablelength(lines)
  local skip_to_next = 0
  local console_output = ""
  command = 'hf mfu i -k %4s'
  msg('Bruteforcing NTAG Passwords\n\nUsing passwords from file: '..infile..'\nTesting '..count_lines..' passwords\nDelay between tests: '..timeout..' ms\n\n'.. pass_text)
  while lines[counter] do
   -- abort if key is pressed
   if core.kbd_enter_pressed() then
    print("aborted by user")
    break
   end
   if password_is_ascii then
    ------------
    -- ASCII 
    ------------
    local slength = string.len(lines[counter]) 
    if string.len(lines[counter]) > 4 then
     print('[!] Skipping password to long: ' .. lines[counter])
     skip_to_next = 1
    else
     password = convert_string_to_hex(lines[counter])
    end
   else
    ------------
    -- HEX
    ------------
    password = lines[counter]                       -- Assume file contained HEX passwords
    if string.len(password) ~= 8 then
     print('[!] WARNING - Skipping password not 8 chars (32 bit HEX): ' .. lines[counter])
     skip_to_next = 1
    else
     if not check_if_string_is_hex(password) then
      print('[!] WARNING - Skipping password not a valid hex string: ' .. lines[counter])
      skip_to_next = 1
     end
    end
   end
   if skip_to_next == 0 then
    local c = string.format( command, password )
    core.console(c)
    if lines[counter] ~= password then 
     print('[=] Tested password '..ansicolors.yellow..ansicolors.bright..lines[counter]..ansicolors.reset..' (Hex: '..password..')')
    else
     print('[=] Tested password '..ansicolors.yellow..ansicolors.bright..lines[counter]..ansicolors.reset)
    end
    passwords_left_to_try = count_lines - counter
    print('[+] Passwords left to try: '..ansicolors.green..ansicolors.bright..passwords_left_to_try .. ansicolors.reset..' of '..ansicolors.green..ansicolors.bright..count_lines..ansicolors.reset)
    print('[=] Ran command: "'..c..'"')
    print('[=] -------------------------------------------------------------')
    core.console('msleep -t'..timeout);
    core.console('hw ping')
    print('[=] -------------------------------------------------------------')
   end
   counter = counter+1
   skip_to_next = 0
  end
  -----------------------------------------------------
  -- END BRUTEFORCE WITH PASSWORDS FROM A FILE       --
  -----------------------------------------------------
 end
end
-------------------------------------------------------------------------------------------------------------
main(args)
-------------------------------------------------------------------------------------------------------------
