######
# Multinotify irssi Client
# nchowning, 2011 - nathanchowning@me.com
######

######
# Parts of this script are based on my irssi-prowl-notifier script which is based
# on fnotify created by Thorsten Leemhuis
# http://www.leemhuis.info/files/fnotify/
######
$VERSION = '1.6';
%IRSSI = (
    authors     => 'Nathan Chowning',
    contact     => 'nathanchowning@me.com',
    name        => 'multinotify-irssi',
    description => 'A script that works with multinotify.py to send irssi notifications',
    url         => 'http://www.nathanchowning.com/projects/multinotify',
    license     => 'GPL'
);

use warnings;
use vars qw($VERSION %IRSSI);
use Irssi;
use JSON;

######
## Set the IP Address & Port for your server below
#######
my $IPADDRESS = "IP ADDRESS IN HERE";
my $PORT = "PORT IN HERE";
my $sslEnabled = 0; # Set to 1 to use SSL

# Determine if SSL should be used
if ($sslEnabled == 1) {
    require IO::Socket::SSL;
} else {
    require IO::Socket::INET;
}

$| = 1; # Flush after write
my ($socket,$client_socket);
my $json = JSON->new->allow_nonref;

######
# Private messages
######
sub private_msg {
	my ($server,$msg,$nick,$address,$target) = @_;
    socketsend($nick,$msg);
}

######
# Nick Flashes
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

    # Create SSL socket or non SSL socket
    # If your server is using a cert signed with a trusted CA, you can change
    # SSL_verify_mode to SSL_VERIFY_PEER
    if ($sslEnabled == 1) {
        $socket = new IO::Socket::SSL->new(
            PeerHost => "$IPADDRESS",
            PeerPort => "$PORT",
            SSL_verify_mode => SSL_VERIFY_NONE
            ) or die "ERROR in Socket Creation : $!\n";
    } else {
        $socket = new IO::Socket::INET (
            PeerHost => "$IPADDRESS",
            PeerPort => "$PORT",
            Proto => "tcp",
            ) or die "ERROR in Socket Creation : $!\n";
    }

    # Tell the server that this is a sending client
    print $socket "SEND" . "\r\n";

    # Create hash & encode json
    my %messagehash = ('app' => "irssi", 'message' => $smessage[1], 'from' => $smessage[0]);
    my $jsonmessage = encode_json \%messagehash;

    # Send the message to the server
    print $socket "$jsonmessage" . "\r\n";

    # Close the socket
    close($socket);
}

######
# Irssi signals
######
Irssi::signal_add_last("message private", "private_msg");
Irssi::signal_add_last("print text", "nick_hilight");
