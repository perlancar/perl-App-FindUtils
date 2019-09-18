package App::FindUtils;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{find_duplicate_files} = {
    v => 1.1,
    summary => 'Search directories recursively and find files/dirs with duplicate names',
    args => {
        dirs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dir',
            schema => ['array*', of=>'dirname*'],
            default => ['.'],
            pos => 0,
            slurpy => 1,
        },
        case_insensitive => {
            schema => 'bool*',
            cmdline_aliases=>{i=>{}},
        },
        detail => {
            summary => 'Instead of just listing duplicate names, return all the location of duplicates',
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub find_duplicate_files {
    require Cwd;
    require File::Find;

    my %args = @_;
    $args{dirs} //= ["."];

    my %files; # filename => {dir_realpath1=>n, ...}. if hash has >1 keys than it's duplicate
    File::Find::find(
        sub {
            no warnings 'once'; # for $File::find::dir
            # XXX inefficient
            my $realdir = Cwd::realpath($File::Find::dir);
            $files{$_}{$realdir}++;
        },
        @{ $args{dirs} }
    );

    my @res;
    for my $file (sort keys %files) {
        next unless keys(%{$files{$file}}) > 1;
        if ($args{detail}) {
            for my $dir (sort keys %{$files{$file}}) {
                push @res, {name=>$file, dir=>$dir};
            }
        } else {
            push @res, $file;
        }
    }
    [200, "OK", \@res];
}

1;
#ABSTRACT: Utilities related to finding files

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

# INSERT_EXECS_LIST


=head1 SEE ALSO

=cut