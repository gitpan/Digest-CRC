# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More tests => 9;

BEGIN { $| = 1; }
use_ok(Digest::CRC, qw(crc32 crc16 crcccitt));

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $input = "123456789";
my ($crc32,$crc16,$crcccitt) = (crc32($input),crc16($input),crcccitt($input));

ok($crc32 == 3421780262, 'crc32'); 
ok($crcccitt == 10673, 'crcccitt'); 
ok($crc16 == 47933, 'crc16'); 

my $ctx;
$ctx = Digest::CRC->new(); 
$ctx->add($input);
ok($ctx->digest == 3421780262, 'OO crc32'); 

$ctx = Digest::CRC->new(type=>"crcccitt"); 
$ctx->add($input);
ok($ctx->digest == 10673, 'OO crcccitt'); 

$ctx = Digest::CRC->new(type=>"crc16"); 
$ctx->add($input);
ok($ctx->digest == 47933, 'OO crc16'); 

$ctx = Digest::CRC->new(width=>16,init=>0,xorout=>0,poly=>0x3456,
                        refin=>1,refout=>1);
$ctx->add($input);
ok($ctx->digest == 12803, 'OO crc16 poly 3456'); 

# crc8 test from Mathis Moder <mathis@pixelconcepts.de>
$ctx = Digest::CRC->new(width=>8, init=>0xab, xorout=>0x00,poly=>0x07,
                        refin=>0, refout=>0);
$ctx->add($input);
ok($ctx->digest == 135, 'OO crc8 poly 07');

