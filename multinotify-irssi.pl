######
# Multinotify irssi Client
# nchowning, 2011 - nathanchowning@me.com
######

######
# Parts of this script are based on my irssi-prowl-notifier script which is based
# on fnotify created by Thorsten Leemhuis
# http://www.leemhuis.info/files/fnotify/
######

use warnings;
use IO::Socket::INET;
use vars qw($VERSION %IRSSI);
use Irssi;

$VERSION = '1.5';
%IRSSI = (
	authors     => 'Nathan Chowning',
	contact     => 'nathanchowning@me.com',
	name        => 'multinotify',
	description => 'A script that works with multinotify-server.py and multinotify-client.pl to send and receive irssi notifications',
	url         => 'http://www.nathanchowning.com/projects/multinotify',
	license     => 'GPL'
);

######
# Set the IP Address & Port for your server below
######

my $IPADDRESS = "IP ADDRESS IN HERE";
my $PORT = "PORT IN HERE";

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
        PeerHost => "$IPADDRESS",
        PeerPort => "$PORT",
        Proto => "tcp",
        ) or die "ERROR in Socket Creation : $!\n";

    # Send "send" to the server to inform it that this is a sending client
    $data = "SEND";
    print $socket "$data" . "\r\n";

    # Send the message to the server
    $data = "$smessage[0],,$smessage[1]";
    print $socket "$data" . "\r\n";

    # Close the socket
    close($socket);
}

######
# Irssi::signal_add_last / Irssi::command_bind
######
Irssi::signal_add_last("message private", "private_msg");
Irssi::signal_add_last("print text", "nick_hilight");
