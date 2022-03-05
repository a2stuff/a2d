#!/usr/bin/env perl

use strict;
use warnings;

my $text = do { local $/; <STDIN> };

my %mli = (
    '$C0' => 'CREATE',
    '$C1' => 'DESTROY',
    '$C2' => 'RENAME',
    '$C3' => 'SET_FILE_INFO',
    '$C4' => 'GET_FILE_INFO',
    '$C5' => 'ON_LINE',
    '$C6' => 'SET_PREFIX',
    '$C7' => 'GET_PREFIX',
    '$C8' => 'OPEN',
    '$C9' => 'NEWLINE',
    '$CA' => 'READ',
    '$CB' => 'WRITE',
    '$CC' => 'CLOSE',
    '$CD' => 'FLUSH',
    '$CE' => 'SET_MARK',
    '$CF' => 'GET_MARK',
    '$D0' => 'SET_EOF',
    '$D1' => 'GET_EOF',
    '$D2' => 'SET_BUF',
    '$D3' => 'GET_BUF',
    '$82' => 'GET_TIME',
    '$40' => 'ALLOC_INTERRUPT',
    '$41' => 'DEALLOC_INTERRUPT',
    '$65' => 'QUIT',
    '$80' => 'READ_BLOCK',
    '$81' => 'WRITE_BLOCK',
    );

my %mgtk = (
    '$00' => 'NoOp',
    '$01' => 'InitGraf',
    '$02' => 'SetSwitches',
    '$03' => 'InitPort',
    '$04' => 'SetPort',
    '$05' => 'GetPort',
    '$06' => 'SetPortBits',
    '$07' => 'SetPenMode',
    '$08' => 'SetPattern',
    '$09' => 'SetColorMasks',
    '$0A' => 'SetPenSize',
    '$0B' => 'SetFont',
    '$0C' => 'SetTextBG',
    '$0D' => 'Move',
    '$0E' => 'MoveTo',
    '$0F' => 'Line',
    '$10' => 'LineTo',
    '$11' => 'PaintRect',
    '$12' => 'FrameRect',
    '$13' => 'InRect',
    '$14' => 'PaintBits',
    '$15' => 'PaintPoly',
    '$16' => 'FramePoly',
    '$17' => 'InPoly',
    '$18' => 'TextWidth',
    '$19' => 'DrawText',
    '$1A' => 'SetZP1',
    '$1B' => 'SetZP2',
    '$1C' => 'Version',
    '$1D' => 'StartDeskTop',
    '$1E' => 'StopDeskTop',
    '$1F' => 'SetUserHook',
    '$20' => 'AttachDriver',
    '$21' => 'ScaleMouse',
    '$22' => 'KeyboardMouse',
    '$23' => 'GetIntHandler',
    '$24' => 'SetCursor',
    '$25' => 'ShowCursor',
    '$26' => 'HideCursor',
    '$27' => 'ObscureCursor',
    '$28' => 'GetCursorAddr',
    '$29' => 'CheckEvents',
    '$2A' => 'GetEvent',
    '$2B' => 'FlushEvents',
    '$2C' => 'PeekEvent',
    '$2D' => 'PostEvent',
    '$2E' => 'SetKeyEvent',
    '$2F' => 'InitMenu',
    '$30' => 'SetMenu',
    '$31' => 'MenuSelect',
    '$32' => 'MenuKey',
    '$33' => 'HiliteMenu',
    '$34' => 'DisableMenu',
    '$35' => 'DisableItem',
    '$36' => 'CheckItem',
    '$37' => 'SetMark',
    '$38' => 'OpenWindow',
    '$39' => 'CloseWindow',
    '$3A' => 'CloseAll',
    '$3B' => 'GetWinPtr',
    '$3C' => 'GetWinPort',
    '$3D' => 'SetWinPort',
    '$3E' => 'BeginUpdate',
    '$3F' => 'EndUpdate',
    '$40' => 'FindWindow',
    '$41' => 'FrontWindow',
    '$42' => 'SelectWindow',
    '$43' => 'TrackGoAway',
    '$44' => 'DragWindow',
    '$45' => 'GrowWindow',
    '$46' => 'ScreenToWindow',
    '$47' => 'WindowToScreen',
    '$48' => 'FindControl',
    '$49' => 'SetCtlMax',
    '$4A' => 'TrackThumb',
    '$4B' => 'UpdateThumb',
    '$4C' => 'ActivateCtl',
    );

$text =~ s/
     \b  jsr \s+ MGTK \n
     \s+ \.byte \s+ (\$[0-9A-F]{2}),\$([0-9A-F]{2}),\$([0-9A-F]{2}) \b
     /"MGTK_CALL " . (exists $mgtk{$1} ? "MGTK::$mgtk{$1}" : $1) . ", \$$3$2"/egx;

$text =~ s/
     \b  jsr \s+ MLI \n
     \s+ \.byte \s+ (\$[0-9A-F]{2}),\$([0-9A-F]{2}),\$([0-9A-F]{2}) \b
     /"MLI_CALL " . (exists $mli{$1} ? "$mli{$1}" : $1) . ", \$$3$2"/egx;

$text =~ s/
     \b  ldy \s+ \#\$([0-9A-F]{2}) \n
     \s+ lda \s+ \#\$([0-9A-F]{2}) \n
     \s+ ldx \s+ \#\$([0-9A-F]{2}) \n
     \s+ jsr \s+ ((?:L|\$)[0-9A-F]{2,4}) \b
     /param_call $4, \$$1, \$$3$2/gx;

$text =~ s/
     \b  lda \s+ \#\$([0-9A-F]{2}) \n
     \s+ ldx \s+ \#\$([0-9A-F]{2}) \n
     \s+ jsr \s+ ((?:L|\$)[0-9A-F]{2,4}) \b
     /param_call $3, \$$2$1/gx;

$text =~ s/
     \b  lda \s+ \#\$([0-9A-F]{2}) \n
     \s+ ldx \s+ \#\$([0-9A-F]{2}) \n
     \s+ jmp \s+ ((?:L|\$)[0-9A-F]{2,4}) \b
     /param_jump $3, \$$2$1/gx;

$text =~ s/
     \b  lda \s+ \#\$([0-9A-F]{2}) \n
     \s+ ldx \s+ \#\$([0-9A-F]{2}) \b
     /ldax    #\$$2$1/gx;

$text =~ s/
     \b  sta \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ stx \s+ ([L\$][0-9A-F]{2,4}) \b
     /(hex(substr($1,1)) + 1 == hex(substr($2,1)))
      ? "stax    $1" : $&/egx;

$text =~ s/
     \b  lsr \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ ror \s+ ([L\$][0-9A-F]{2,4}) \b
     /(hex(substr($1,1)) == hex(substr($2,1)) + 1)
      ? "lsr16   $2" : $&/egx;

$text =~ s/
     \b  lda \s+ \#\$([0-9A-F]{2}) \n
     \s+ sta \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ lda \s+ \#\$([0-9A-F]{2}) \n
     \s+ sta \s+ ([L\$][0-9A-F]{2,4}) \b
     /(hex(substr($2,1)) + 1 == hex(substr($4,1))) ? "copy16  #\$$3$1, $2" : $&/egx;

$text =~ s/
     \b  lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ sta \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ sta \s+ ([L\$][0-9A-F]{2,4}) \b
     /(hex(substr($1,1)) + 1 == hex(substr($3,1))) &&
      (hex(substr($2,1)) + 1 == hex(substr($4,1)))
       ? "copy16  $1, $2" : $&/egx;

$text =~ s/
     \b  lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ clc \n
     \s+ adc \s+ \#\$([0-9A-F]{2}) \n
     \s+ sta \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ adc \s+ \#\$([0-9A-F]{2}) \n
     \s+ sta \s+ ([L\$][0-9A-F]{2,4}) \b
     /(hex(substr($1,1)) + 1 == hex(substr($4,1))) &&
      (hex(substr($3,1)) + 1 == hex(substr($6,1)))
      ? "add16   $1, #\$$5$2, $3" : $&/egx;

$text =~ s/
     \b  lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ clc \n
     \s+ adc \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ sta \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ adc \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ sta \s+ ([L\$][0-9A-F]{2,4}) \b
     /(hex(substr($1,1)) + 1 == hex(substr($4,1))) &&
      (hex(substr($2,1)) + 1 == hex(substr($5,1))) &&
      (hex(substr($3,1)) + 1 == hex(substr($6,1)))
      ? "add16   $1, $2, $3" : $&/egx;

$text =~ s/
     \b  lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ sec \n
     \s+ sbc \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ sta \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ sbc \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ sta \s+ ([L\$][0-9A-F]{2,4}) \b
     /(hex(substr($1,1)) + 1 == hex(substr($4,1))) &&
      (hex(substr($2,1)) + 1 == hex(substr($5,1))) &&
      (hex(substr($3,1)) + 1 == hex(substr($6,1)))
      ? "sub16   $1, $2, $3" : $&/egx;

$text =~ s/
     \b  lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ cmp \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ sbc \s+ ([L\$][0-9A-F]{2,4}) \b
     /(hex(substr($1,1)) + 1 == hex(substr($3,1))) &&
      (hex(substr($2,1)) + 1 == hex(substr($4,1)))
      ? "cmp16   $1, $2" : $&/egx;

$text =~ s/
     \b  lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ cmp \s+ \#\$([0-9A-F]{2}) \n
     \s+ lda \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ sbc \s+ \#\$([0-9A-F]{2}) \b
     /(hex(substr($1,1)) + 1 == hex(substr($3,1)))
      ? "cmp16   $1, #\$$4$2" : $&/egx;

$text =~ s/
     \b  inc \s+ ([L\$][0-9A-F]{2,4}) \n
     \s+ bne \s+ (\w+) \n
     \s+ inc \s+ ([L\$][0-9A-F]{2,4}) \n
\2:  /(hex(substr($1,1)) + 1 == hex(substr($3,1)))
      ? "inc16   $1\n$2:" : $&/egx;

$text =~ s/
     \b  lda \s+ ( (?: [L\$][0-9A-F]{2,4} ) | (?: \#\$[0-9A-F]{2} ) ) \n
     \s+ rts \b
     /return  $1/gx;

$text =~ s/
     \b  brk \b
     /.byte   0/gx;

print $text;
