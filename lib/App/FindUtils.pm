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
        eval => {
            #schema => 'code_from_str::local_topic*', # not yet available
            schema => 'str*',
            description => <<'MARKDOWN',

Process filename through this code. Code will receive filename in `$_` and is
expected to change and return a new "name" that will be compared for duplicate
instead of the original name. You can use this e.g. to find duplicate in some
part of the filename. As an alternative, see the `--regex` option.

MARKDOWN
            cmdline_aliases => {e=>{}},
        },
        regex => {
            schema => 're_from_str*',
            description => <<'MARKDOWN',

Specify a regex with a capture to get part of the filename. The first capture
`$1` will be used to compare for duplicate instead of the original name. You can
use this to find duplicate in some part of the filename. As an alternative, see
the `--eval` option.

MARKDOWN
            cmdline_aliases => {r=>{}},
        },
        exclude_filename_regex => {
            schema => 're_from_str*',
            summary => 'Filename regex to exclude',
            cmdline_aliases => {x=>{}},
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
        {
            summary => "Find duplicate receipts by order ID (filenames are named receipt-order=12345.pdf), exclude backup files",
            test => 0,
            'x.doc.show_result' => 0,
            src => q{[[prog]] -x '/\\.bak$/' -r '/order=(\\d+)/' --debug},
            src_plang => 'bash',
        },
    ],
    args_rels => {
        choose_one => ['eval', 'regex'],
    },
};
sub find_duplicate_filenames {
    require Cwd;
    require File::Find;

    my %args = @_;
    $args{dirs} //= ["."];
    my $eval;
    if (defined $args{eval}) {
        my $code = "no strict; no warnings; package main; sub { local \$_=\$_; " . $args{eval} . "; return \$_ }";
        $eval = eval $code or return [400, "Can't compile code in eval: $@"]; ## no critic: BuiltinFunctions::ProhibitStringyEval
    } elsif (defined $args{regex}) {
        $eval = sub { /$args{regex}/; $1 };
    }

    #my $ci = $args{case_insensitive};

    my %names; # filename (or name) => {realpath1=>1, ...}. if hash has >1 keys than it's duplicate
    File::Find::find(
        sub {
            no warnings 'once'; # for $File::find::dir
            # XXX inefficient
            my $realpath = Cwd::realpath($_);
            log_debug "Found path $realpath";

            if ($args{exclude_filename_regex}) {
                if ($_ =~ $args{exclude_filename_regex}) {
                    log_info "$_ excluded (matches --exclude-filename-regex: $args{exclude_filename_regex})";
                    return;
                }
            }

            my $name;
            if ($eval) {
                $name = $eval->();
            } else {
                $name = $_;
            }

            $names{$name}{$realpath}++;
        },
        @{ $args{dirs} }
    );

    my @res;
    for my $name (sort keys %names) {
        next unless keys(%{$names{$name}}) > 1;
        log_info "%s is a DUPLICATE name (found in %d paths: %s)", $name, scalar(keys %{$names{$name}}), join(", ", sort(keys %{$names{$name}}));
        if ($args{detail}) {
            for my $path (sort keys %{$names{$name}}) {
                push @res, {name=>$name, path=>$path};
            }
        } else {
            push @res, $name;
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
