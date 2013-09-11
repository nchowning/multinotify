#!/usr/bin/perl

######
# Multinotify Desktop Client
# nchowning, 2011 - nathanchowning@me.com
#
# Warning: This may not work. I've bandaided it to work with the new
# multinotify server but I have not tested it very far
######

# Set the app name and load the socket module
use constant APP_NAME => 'multinotify-client';
use IO::Socket::INET;

my $IPADDRESS = "IP ADDRESS IN HERE";
my $PORT = "PORT IN HERE";
my $notifier;

# Check to see which notification modules are installed
# If none are installed, die
if (eval{ require Gtk2::Notify; })
{
    # If you experience notify-init() errors, uncomment the following line
    #use Gtk2::Notify  -init, 'Multinotify';
    $notifier = 'libnotify';
}
elsif (eval{ require Cocoa::Growl; })
{
    $notifier = 'growl';
}
else
{
    print "!!!No notifier module installed!!!\n
        Multinotify currently has built-in support for libnotify (Gtk2::Notify) and Growl (Cocoa::Growl).\n";
    die;
}

# Flush
$| = 1;
my ($socket,$client_socket);

# Socket variable initialization
$socket = new IO::Socket::INET (
    PeerHost => "$IPADDRESS",
    PeerPort => "$PORT",
    Proto => 'tcp',
    ) or die "ERROR in Socket Creation : $!\n";
print "Connection Successful.\n";

# Tell the server that this is a GET client
$data = "GET";
print $socket "$data" . "\r\n";

# Await the server's confirmation
$received = <$socket>;
print "Connected as " . $received;

while(1)
{
    # Store the received data (from the server) in $received and split
    # it into @receivear
    $received = <$socket>;
    chomp($received);
    my @receivear = split(",,",$received);

        print "$receivear[1]: $receivear[2]\n";
        notify($receivear[1], $receivear[2]);
}
$socket->close();

sub notify
{
    # Set the username & message that is passed to this function
    my($username, $message) = @_;

    if ($notifier eq 'libnotify')
    {
        ######
        # Need to add line breaks at a certain point as libnotify doesn't
        # clean that up for you (like growl does).
        ######

        # Strip '<' and '>' from the message
        $message =~ s/<//g;
        $message =~ s/>//g;

        # Create the notification
        my $notification = Gtk2::Notify->new($username, $message, 'irssi.png');

        # Show the notification
        $notification->show;
    }
    elsif ($notifier eq 'growl')
    {
        # Create growl notifier
        Cocoa::Growl::growl_register(
            app           => 'irssi',
            icon          => 'irssi.png',
            notifications => [qw(irssi)],
        );
        
        # Show growl notification
        Cocoa::Growl::growl_notify(
            name        => 'irssi',
            title       => "Message from: $username",
            description => "$message"
        );
    }
}
