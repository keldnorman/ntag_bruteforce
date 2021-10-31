# ntag_bruteforce
LUA Script to Bruteforce NFC tags of the type NTAG21x using a Proxmark RDV4.0 - only for 32-bit codes.

Place this script in your local proxmark folder or in ${HOME}/.proxmark3/luascripts/

Then start proxmark3: 

root@pc:~/source/Proxmark# service ModemManager stop
root@pc:~/source/Proxmark# stty -F /dev/ttyACM0 115200 cs8 -cstopb -parenb raw -echo -echoe -echok
root@pc:~/source/Proxmark# proxmark3 /dev/ttyACM0 

[=] Session log /root/.proxmark3/logs/log_20211031.txt
[+] loaded from JSON file /root/.proxmark3/preferences.json
[=] Using UART port /dev/ttyACM0
[=] Communicating with PM3 over USB-CDC


  ██████╗ ███╗   ███╗█████╗ 
  ██╔══██╗████╗ ████║╚═══██╗
  ██████╔╝██╔████╔██║ ████╔╝
  ██╔═══╝ ██║╚██╔╝██║ ╚══██╗
  ██║     ██║ ╚═╝ ██║█████╔╝ 
  ╚═╝     ╚═╝     ╚═╝╚════╝     [ ❄ Iceman ❄ ]

 [ Proxmark3 RFID instrument ]

 [ CLIENT ]
  client: RRG/Iceman/master/v4.14434-17-g1cc1a3857 2021-10-06 14:24:04
  compiled with GCC 10.3.0 OS:Linux ARCH:x86_64

 [ PROXMARK3 ]
  device.................... RDV4
  firmware.................. RDV4
  external flash............ present
  smartcard reader.......... present
  FPC USART for BT add-on... absent

 [ ARM ]
  bootrom: RRG/Iceman/master/v4.14434-17-g1cc1a3857 2021-10-06 14:24:24
       os: RRG/Iceman/master/v4.14434-17-g1cc1a3857 2021-10-06 14:24:37
  compiled with GCC 8.3.1 20190703 (release) [gcc-8-branch revision 273027]

 [ FPGA ] 
  LF image built for 2s30vq100 on 2020-07-08 at 23:08:07
  HF image built for 2s30vq100 on 2020-07-08 at 23:08:19
  HF FeliCa image built for 2s30vq100 on 2020-07-08 at 23:08:30

 [ Hardware ]
  --= uC: AT91SAM7S512 Rev B
  --= Embedded Processor: ARM7TDMI
  --= Internal SRAM size: 64K bytes
  --= Architecture identifier: AT91SAM7Sxx Series
  --= Embedded flash memory 512K bytes ( 59% used )

HOW TO RUN THE SCRIPT:

[usb] pm3 --> script run ntag_bruteforce.lua -i  /root/.proxmark3/luascripts/keys/testkeys.list -h

Script      : ntag_bruteforce.lua
Author      : Keld Norman
Version     : 1.0.0
Description : Bruteforces 7 byte UID NTAG protected with a 32 bit password

      .-.
     /   \         .-.
    /     \       /   \       .-.     .-.     _   _
+--/-------\-----/-----\-----/---\---/---\---/-\-/-\/\/---
  /         \   /       \   /     '-'     '-'
 /           '-'         '-'
 
Usage:

script run ntag_bruteforce [-s <start_id>] [-e <end_id>] [-t <timeout>] [ -o <output_file> ] [ -h for help ]
script run ntag_bruteforce [-i <input_file>] [-t <timeout>] [ -o <output_file> ] [ -h for help ] -x

DESCRIPTION 

This script will test either an 8 digit hexadecimal code or 4 char stings (will be converted to an 8 digit hex string )
against NFC cards of the type NTAG21x protected by a 32 bit password.

Read more about NTAGs here: https://www.nxp.com/docs/en/data-sheet/NTAG213_215_216.pdf

Arguments

    -i       input_file           Read 4 char ASCII values to test from this file (will override -s and -e )
    -x                            Password file (-i) contains HEX values (4 x 2hex -> 32 bit/line)
    -o       output_file          Write output to this file
    -s       0-0xFFFFFFFF         start id
    -e       0-0xFFFFFFFF         end id
    -t       0-99999, pause       timeout (ms) between cards 1000 = 1 second
                                  (use the word 'pause' to wait for user input)
    -h       this help

EXAMPLES:
  
# Example of how to run the script with bruteforcing of continuously HEX numbers with 1 secound delay between tests:
 script run ntag_bruteforce -s 00000000 -e FFFFFFFF -t 1000  -o /var/log/ntag_bruteforce.log 

# Example of how to run the script and bruteforc the card using passwords from the input file with 1s delay between tests
 script run ntag_bruteforce -i /home/my_4_char_passwords_list.txt -o /var/log/ntag_bruteforce.log 

[+] finished ntag_bruteforce.lua

TEST A CARD WITH A CUSTOM PASSWORD LIST 
  
[usb] pm3 --> script run ntag_bruteforce.lua -i  /root/.proxmark3/luascripts/keys/testkeys.list -x

If you add -x and specify a password file to use for the bruteforce then the content will be treated as HEX so the file must contain 
one 32-bit HEX values / line
  
Example: 
  
root@pc:~/source/Proxmark# cat /here/is/my/password_list_file.txt
00000000
FFFFFFFF
12345678

Running the script with -i your_file but without the -x then the file will be treated as if the passwords were ascii
Because 32-bit = 8 bit then the ascii code must only be 4-chars long for this type of attack 
  If you add ascii strings instead then they must only be at max 4 chars/digits like this:
  
1234
abcs
NTAG
FFFF

[![Watch the video]()](https://github.com/keldnorman/ntag_bruteforce/blob/main/Ntag-1.webm)

  
