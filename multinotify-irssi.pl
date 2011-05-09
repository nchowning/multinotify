use warnings;
use IO::Socket::INET;
use vars qw($VERSION %IRSSI);

use Irssi;
$VERSION = '0.1';
%IRSSI = (
	authors     => 'Nathan Chowning',
	contact     => 'nathanchowning@me.com',
	name        => 'multinotify',
	description => 'A script that works with multinotify-server.pl and multinotify-client.pl to send and receive irssi notifications',
	url         => 'http://www.nathanchowning.com/projects/multinotify',
	license     => 'GPL'
);

######
# Parts of this script are based on my irssi-prowl-notifier script which is based
# on fnotify created by Thorsten Leemhuis
# http://www.leemhuis.info/files/fnotify/
######

$| = 1; # Flush after write
my ($socket,$client_socket);

######
# Private message parsing
######
sub private_msg {
	my ($server,$msg,$nick,$address,$target) = @_;
    socketsend($nick,$msg);
}

######
# Sub to catch nick hilights
######
sub nick_hilight {
    my ($dest, $text, $stripped) = @_;
    if ($dest->{level} & MSGLEVEL_HILIGHT) {
	socketsend($dest->{target}, $stripped);
    }
}

######
# Send messages to notification server
######
sub socketsend {
    my(@smessage) = @_;
    $socket = new IO::Socket::INET (
        PeerHost => 'IP_ADDRESS',
        PeerPort => 'PORT_NUMBER',
        Proto => 'tcp',
        ) or die "ERROR in Socket Creation : $!\n";

    # Send "send" to the server to inform it that this is a sending client
    $data = "send";
    print $socket "$data\n";

    # If the server approves our connection, send the username to the server
    if (<$socket> eq "approved\n")
    {
        $data = $smessage[0];
        print $socket "$data\n";
    }

    # If the server receives the username successfully, send the message to the server
    if (<$socket> eq "un\n")
    {
        $data = $smessage[1];
        print $socket "$data\n";
    }

    # Close the socket
    close($socket);
}

######
# Irssi::signal_add_last / Irssi::command_bind
######
Irssi::signal_add_last("message private", "private_msg");
Irssi::signal_add_last("print text", "nick_hilight");
