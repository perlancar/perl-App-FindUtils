package App::FindUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

$SPEC{find_duplicate_filenames} = {
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
        #case_insensitive => {
        #    schema => 'bool*',
        #    cmdline_aliases=>{i=>{}},
        #},
        detail => {
            summary => 'Instead of just listing duplicate names, return all the location of duplicates',
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    examples => [
        {
            summary => "Find duplicate filenames under the current directory",
            test => 0,
            'x.doc.show_result' => 0,
            src => '[[prog]]',
            src_plang => 'bash',
        },
    ],
};
sub find_duplicate_filenames {
    require Cwd;
    require File::Find;

    my %args = @_;
    $args{dirs} //= ["."];
    #my $ci = $args{case_insensitive};

    my %files; # filename => {realpath1=>orig_filename, ...}. if hash has >1 keys than it's duplicate
    File::Find::find(
        sub {
            no warnings 'once'; # for $File::find::dir
            # XXX inefficient
            my $realpath = Cwd::realpath($_);
            log_debug "Found path $realpath";
            $files{$_}{$realpath}++;
        },
        @{ $args{dirs} }
    );

    my @res;
    for my $file (sort keys %files) {
        next unless keys(%{$files{$file}}) > 1;
        log_info "%s is a DUPLICATE name (found in %d paths)", $file, scalar(keys %{$files{$file}});
        if ($args{detail}) {
            for my $path (sort keys %{$files{$file}}) {
                push @res, {name=>$file, path=>$path};
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

L<uniq-files> from L<App::UniqFiles>

=cut
