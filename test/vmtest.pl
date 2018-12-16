use strict;
use warnings;

my $__VM_TESTS_FAILED__ = 0;

sub assert_output {
    my ($string, $exp_out, $exp_stat) = @_;
    my (undef, $filename, $line) = caller;

    my $RED = "\x1B[31m";
    my $END = "\x1B[0m";
    my $debug_dump = '/dump.ysl';
    my $debug_yasl = '/YASL';

    open(my $fh, '>', '..' . $debug_dump) or die "Could not open file $debug_dump";
    print $fh "$string";
    close $fh;

    my $output = qx/"..$debug_yasl" "..$debug_dump"/;
    my $status = $?;
    my $exitcode = !($output eq $exp_out && $status == $exp_stat) || 0;

    if ($output ne $exp_out) {
        print $RED . "output assert failed in $filename (line $line): $exp_out =/= $output" . $END . "\n";
    }
    if ($status != $exp_stat) {
        print $RED . "exitcode assert failed in $filename (line $line): $status =/= $exp_stat" . $END . "\n";
    }

    $__VM_TESTS_FAILED__ ||= $exitcode;
    return $exitcode;
}


# Literals
assert_output("echo 0x10\n", "16\n", 0);
assert_output("echo 0b1010\n", "10\n", 0);
assert_output(q+echo '\ttab'
               +,
              "\ttab\n", 0);
assert_output(q+echo `no escapes\a\b\f\n\r\t\v\0\'\\\\`
               +,
              'no escapes\a\b\f\n\r\t\v\0\\\'\\\\
', 0);
assert_output(q+let $x = 10
                let $y = 12
                echo "$x is #{$x->tostr()}, #{$y->tostr()}.";+,
              "\$x is 10, 12.\n",
              0);

# Comprehensions
assert_output(qq"for let i <- [x*2 for let x <- [1, 2, 3]] {
                    echo i;
                 }\n",
              "2\n4\n6\n", 0);
assert_output(qq"for let i <- [x*2 for let x <- [1, 2, 3, 4, 5, 6] if x % 2 == 0] {
                    echo i;
                 }\n",
              "4\n8\n12\n", 0);
assert_output(qq"let x = { x*2:-x for let x <- [1, 2, 3, 4] if x % 2 == 0}
                 for let i <- x {
                      echo i
                      echo x[i]
                 }\n",
              "8\n-4\n4\n-2\n", 0);
assert_output(qq"let x = { x*2:-x for let x <- [1, 2, 3]}
                 for let i <- x {
                      echo i
                      echo x[i]
                 }\n",
              "6\n-3\n2\n-1\n4\n-2\n", 0);


# Unary Operators
assert_output("echo -10\n", "-10\n", 0);
assert_output("echo len'YASL'\n", "4\n", 0);
assert_output("echo !true\n", "false\n", 0);
assert_output("echo !false\n", "true\n", 0);
assert_output("echo ^0b00000000\n", "-1\n", 0);

# Binary Operators
assert_output("echo 2 ** 4\n", "16\n", 0);
assert_output("echo 2 ** -1\n", "0.5\n", 0);
assert_output("echo -2 ** -1\n", "-0.5\n", 0);

assert_output("echo 5 * 6\n", "30\n", 0);
assert_output("echo 5 / 2\n", "2.5\n", 0);
assert_output("echo 6 // 2\n", "3\n", 0);
assert_output("echo 5 % 2\n", "1\n", 0);

assert_output("echo 10 + 12\n", "22\n", 0);
assert_output("echo 3.5 - 2\n", "1.5\n", 0);

assert_output("echo 1 || 2\n", "1\n", 0);
assert_output("echo 1 && 2\n", "2\n", 0);

assert_output("echo 'str1' < 'str2'\n", "true\n", 0);
assert_output("echo 'str1' > 'str2'\n", "false\n", 0);
assert_output("echo 'str1' <= 'str2'\n", "true\n", 0);
assert_output("echo 'str1' >= 'str2'\n", "false\n", 0);

assert_output("echo 'str1' < 'str12'\n", "true\n", 0);
assert_output("echo 'str1' <= 'str12'\n", "true\n", 0);
assert_output("echo 'str1' >= 'str12'\n", "false\n", 0);
assert_output("echo 'str1' > 'str12'\n", "false\n", 0);

assert_output("echo 'str1' > 'str1'\n", "false\n", 0);
assert_output("echo 'str1' < 'str1'\n", "false\n", 0);
assert_output("echo 'str1' >= 'str1'\n", "true\n", 0);
assert_output("echo 'str1' <= 'str1'\n", "true\n", 0);

assert_output("echo 'str1' == 'str2'\n", "false\n", 0);
assert_output("echo 'str1' == 'str12'\n", "false\n", 0);
assert_output("echo 'str1' == 'str1'\n", "true\n", 0);

# Ternary Operator
assert_output("echo true ? 1 : 0\n", "1\n", 0);
assert_output("echo false ? 1 : 0\n", "0\n", 0);

# If Statements
assert_output(qq"let x = true
                 if x { echo 1; } else { echo 0; };",
              "1\n", 0);
assert_output(qq"let x = false
                 if x { echo 1; } else { echo 0; };",
              "0\n", 0);
assert_output(qq"let x = 1
                 if x > 0 { echo '+'; } elseif x < 0 { echo '-'; } else { echo '0'; };",
              "+\n", 0);
assert_output(qq"let x = -1
                 if x > 0 { echo '+'; } elseif x < 0 { echo '-'; } else { echo '0'; };",
              "-\n", 0);
assert_output(qq"let x = 0
                 if x > 0 { echo '+'; } elseif x < 0 { echo '-'; } else { echo '0'; };",
              "0\n", 0);

# While Loops
assert_output(qq"let n = 10
                 while n > 0 { echo n; n -= 1; };",
              "10\n9\n8\n7\n6\n5\n4\n3\n2\n1\n", 0);
assert_output(qq"let n = 10
                 while n > 0 { if n == 5 { n -= 1; continue; }; echo n; n -= 1; };",
              "10\n9\n8\n7\n6\n4\n3\n2\n1\n", 0);
assert_output(qq"let n = 10
                 while n > 0 { if n == 5 { break; }; echo n; n -= 1; };",
              "10\n9\n8\n7\n6\n", 0);

# Numeric For Loops
assert_output(qq"for let n = 10; n > 0; n -= 1 { echo n; };",
              "10\n9\n8\n7\n6\n5\n4\n3\n2\n1\n", 0);
assert_output(qq"for let n = 10; n > 0; n -= 1 { if n == 5 { continue; }; echo n; };",
              "10\n9\n8\n7\n6\n4\n3\n2\n1\n", 0);
assert_output(qq"for let n = 10; n > 0; n -= 1 { if n == 5 { break; }; echo n; };",
              "10\n9\n8\n7\n6\n", 0);

# Iterative For Loops
assert_output(qq"for let i <- [10, 9, 8, 7, 6, 5, 4, 3, 2, 1] { echo i; };",
              "10\n9\n8\n7\n6\n5\n4\n3\n2\n1\n", 0);
assert_output(qq"for let i <- [10, 9, 8, 7, 6, 5, 4, 3, 2, 1] { if i == 5 { continue; }; echo i; };",
              "10\n9\n8\n7\n6\n4\n3\n2\n1\n", 0);
assert_output(qq"for let i <- [10, 9, 8, 7, 6, 5, 4, 3, 2, 1] { if i == 5 { break; };  echo i; };",
              "10\n9\n8\n7\n6\n", 0);

# Functions
assert_output(qq"fn add(a, b) { return a + b; }
                 echo add(10, 11);",
              "21\n", 0);
assert_output(qq"let x = 10
                 fn add(a, b) { let sum = a + b; return sum; }
                 echo add(10, 11)
                 echo x;",
              "21\n10\n", 0);

# Integer Methods
assert_output("echo 2->tofloat()\n", "2.0\n", 0);
assert_output("echo 5->tostr()\n", "5\n", 0);

# Float Methods
assert_output("echo 2.1->toint()\n", "2\n", 0);
assert_output("echo 5.7->tostr()\n", "5.7\n", 0);

# Boolean Methods
assert_output("echo true->tostr()\n", "true\n", 0);
assert_output("echo false->tostr()\n", "false\n", 0);

# String Methods
assert_output("echo 'yasl'->tobool()\n", "true\n", 0);
assert_output("echo ''->tobool()\n", "false\n", 0);
assert_output("echo 'yasl'->tostr()\n", "yasl\n", 0);
assert_output("echo 'yasl'->toupper()\n", "YASL\n", 0);
assert_output("echo 'Yasl'->toupper()\n", "YASL\n", 0);
assert_output("echo 'Yasl'->tolower()\n", "yasl\n", 0);
assert_output("echo 'Yasl12_'->isalnum()\n", "false\n", 0);
assert_output("echo 'YASL1223121321'->isalnum()\n", "true\n", 0);
assert_output("echo 'YASL1223121321'->isal()\n", "false\n", 0);
assert_output("echo 'YASLDSADASDAS'->isal()\n", "true\n", 0);
assert_output("echo 'YASLDSADASDAS'->isnum()\n", "false\n", 0);
assert_output("echo '12341213421'->isnum()\n", "true\n", 0);
assert_output("echo '12341213421'->isspace()\n", "false\n", 0);
assert_output("echo '  '->isspace()\n", "true\n", 0);
assert_output("echo 'YASL'->startswith('YA')\n", "true\n", 0);
assert_output("echo 'YASL'->startswith('A')\n", "false\n", 0);
assert_output("echo 'YASL'->endswith('ASL')\n", "true\n", 0);
assert_output("echo 'YASL'->endswith('YA')\n", "false\n", 0);
assert_output("echo 'YASL'->replace('T', 'S')\n", "YASL\n", 0);
assert_output("echo 'YASL'->replace('SL', '')\n", "YA\n", 0);
assert_output("echo 'YASL'->search('A')\n", "1\n", 0);
assert_output("echo 'YASL'->search('0')\n", "undef\n", 0);
assert_output("echo len 'the quick brown fox'->split(' ')\n", "4\n", 0);
assert_output("for let x <- 'the quick brown fox'->split(' ') { echo x; };", "the\nquick\nbrown\nfox\n", 0);
assert_output("echo len 'the quick brown fox'->split('0')\n", "1\n", 0);
assert_output("echo 'YAY'->ltrim('Y')\n", "AY\n", 0);
assert_output("echo 'YYYYAY'->ltrim('Y')\n", "AY\n", 0);
assert_output("echo 'YAY'->ltrim('A')\n", "YAY\n", 0);
assert_output("echo 'YAY'->rtrim('Y')\n", "YA\n", 0);
assert_output("echo 'YAYYYY'->rtrim('Y')\n", "YA\n", 0);
assert_output("echo 'YAY'->rtrim('A')\n", "YAY\n", 0);
assert_output("echo 'YAY'->trim('Y')\n", "A\n", 0);
assert_output("echo 'YAY'->trim('A')\n", "YAY\n", 0);
assert_output("echo 'YYAYYY'->trim('Y')\n", "A\n", 0);
assert_output("echo 'YASL'->__get(3)\n", "L\n", 0); 
assert_output("echo 'YASL'->__get(-1)\n", "L\n", 0);

# List Methods
assert_output(qq"let x = [0]
                 x->push(1) 
                 for let e <- x { echo e; }\n", "0\n1\n", 0);
assert_output(qq"let x = [1, 2, 3]
               echo x->pop()
               for let e <- x { echo e; }\n", "3\n1\n2\n", 0);
assert_output(qq"let x = [1, 2, 3]
                 x->extend([4, 5, 6])
                 for let e <- x { echo e; }\n", "1\n2\n3\n4\n5\n6\n", 0);
assert_output(qq"let x = [1, 2, 3]
                 echo x->search(4)\n", "undef\n", 0);
assert_output(qq"let x = [1, 2, 4]
                 echo x->search(4)\n", "2\n", 0);
assert_output(qq"let x = [1, 2, 3, 4, 5]
                 x->reverse()
                 for let e <- x { echo e; }\n", "5\n4\n3\n2\n1\n", 0);
assert_output(qq"for let e <- [1, 2, 3]->copy() { echo e; };", "1\n2\n3\n", 0);
assert_output(qq"let x = [1, 2, 3]
                 x[1] = 0
                 for let e <- x { echo e; }\n", "1\n0\n3\n", 0);
assert_output(qq"let x = [1, 2, 3] 
                 echo x[0]
                 echo x[1]
                 echo x[2]\n", "1\n2\n3\n", 0);
 
# Table Methods
assert_output(qq"let x = {1:'one', 2:'two', 3:'three'}
                 for let e <- x->keys() { echo e; }\n", "3\n1\n2\n", 0);
assert_output(qq"let x = {1:'one', 2:'two', 3:'three'}
                 for let e <- x->values() { echo e; }\n", "three\none\ntwo\n", 0);
assert_output(qq"let x = {1:'one', 2:'two', 3:'three'}
                 x[1] = 'un'
                 echo x[1]
                 for let e <- x { echo e; }\n", "un\n3\n1\n2\n", 0);
assert_output(qq"let x = {1:'one', 2:'two', 3:'three'}
                 x[1] = 'un'
                 for let e <- x->values() { echo e; }\n", "three\nun\ntwo\n", 0);
assert_output(qq"let x = {1:'one', 2:'two', 3:'three'};
                 for let e <- x->copy() { echo e; echo x[e]; };", "3\nthree\n2\ntwo\n1\none\n", 0);

# General
assert_output(qq"let x = []
                 let i = 0
                 while i < 1000000 {
                     x->push(i)
                     i += 1
                 };",
              "",
              0);

assert_output(qq"x := 10
                 y := x + 10
                 echo x
                 echo y
                ",
              "10\n20\n",
              0);

assert_output(qq"const x = 10
                 const y := x + 10
                 echo x
                 echo y
                ",
              "10\n20\n",
              0);

exit $__VM_TESTS_FAILED__;
