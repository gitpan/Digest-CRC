BEGIN {
  $tests = 16;
  $| = 1;

  eval "use Test::More tests => $tests";

  $@ and eval <<'ENDEV';
$ok = 1;

print "1..$tests\n";

sub ok {
  my($res,$comment) = @_;
  defined $comment and print "# $comment\n";
  $res or print "not ";
  print "ok ", $ok++, "\n";
}
ENDEV
}

use Digest::CRC qw(crc32 crc16 crcccitt crc8);
ok(1, 'use');

my $input = "123456789";
my ($crc32,$crc16,$crcccitt,$crc8) = (crc32($input),crc16($input),crcccitt($input),crc8($input));

ok($crc32 == 3421780262, 'crc32'); 
ok($crcccitt == 10673, 'crcccitt'); 
ok($crc16 == 47933, 'crc16'); 
ok($crc8 == 244, 'crc8'); 

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

$ctx = Digest::CRC->new(type=>"crc8");
$ctx->add($input);
ok($ctx->digest == 244, 'OO crc8');

# crc8 test from Mathis Moder <mathis@pixelconcepts.de>
$ctx = Digest::CRC->new(width=>8, init=>0xab, xorout=>0x00,poly=>0x07,
                        refin=>0, refout=>0);
$ctx->add($input);
ok($ctx->digest == 135, 'OO crc8 init=ab');

$ctx = Digest::CRC->new(width=>8, init=>0xab, xorout=>0xff,poly=>0x07,
                        refin=>1, refout=>1);
$ctx->add("f1");
ok($ctx->digest == 106, 'OO crc8 init=ab, refout');

$input = join '', 'aa'..'zz';
($crc32,$crc16,$crcccitt,$crc8) = (crc32($input),crc16($input),crcccitt($input),crc8($input));

# some more large messages
ok($crc32 == 0xCDA63E54, 'crc32'); 
ok($crcccitt == 0x9702, 'crcccitt'); 
ok($crc16 == 0x0220, 'crc16'); 
ok($crc8 == 0x82, 'crc8'); 
