use Irssi;
use Irssi::Irc;
use File::Basename;
use File::Spec;
use feature "switch";
use strict;


use vars qw($VERSION %IRSSI);


$VERSION = "0.01";
%IRSSI   = (
    authors     => "Christopher MacGown",
    name        => "AutoCommand",
    description => "Automatically run commands after joining a channel.",
    license     => "Proprietary",
    changed     => "Fri Jul 18 11:09:33 PDT 2014",
);

sub mkdir_p($) { 
    my $dir = shift;
    return if (-d $dir);
    mkdir_p(dirname($dir));
    mkdir $dir;
}

sub sync {
    my $channel = shift;
    channel_execute($channel->{server}, $channel)
}

sub handle_commands_path {
    my $server_name = shift;
    my $commands_path = Irssi::settings_get_str('autocommand_settings_path');

    $commands_path = File::Spec->catfile(
                        File::Spec->rel2abs(glob($commands_path)),
                        $server_name,
                     );

    unless ( -d $commands_path ) { 
        Irssi::printformat(MSGLEVEL_CLIENTCRAP,
                           'autoload_creating',
                           $commands_path);
        mkdir_p($commands_path);
    } else {
        Irssi::printformat(MSGLEVEL_CLIENTCRAP,
                           'autoload_exists',
                           $commands_path);
    }

    return $commands_path;
}

sub channel_execute { 
    my ($server, $channel) = @_;
    my $server_name  = lc($server->{tag});
    my $channel_name = lc($channel->{name});
    my $file_path = File::Spec->catfile(handle_commands_path(lc($server->{tag})),
                                        lc($channel->{name}));
    return unless (-e $file_path);

    Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'autoload_loading', $file_path);
    open(FILE, $file_path);
    while (<FILE>) {
        chomp;
        my ($type, $command) = split('\r', $_);

        given ($type) { 
            when (/^raw/)     { $server->send_raw($command) }
            when (/^message/) { $server->command("MSG " . $channel->{name} . " " . $command) }
            default           { Irssi::printformat(MSGLEVEL_CLIENTCRAP,
                                                   'autoload_warning',
                                                   $type,
                                                   $command)
            }
        }
    }
    close(FILE);
}

Irssi::theme_register([
    'autoload_warning', 'Warning! Don\'t know how to %_$0%_ with %_$1%_',
    'autoload_creating', 'recursively creating: %_$0%_',
    'autoload_exists', 'autocommand directory exists: %_$0%_',
    'autoload_loading', 'Loading %_$0%_',
]);

Irssi::settings_add_str('misc', 'autocommand_settings_path',
                        '~/.irssi/scripts/autocommand');
Irssi::signal_add({'channel sync' => \&sync});
