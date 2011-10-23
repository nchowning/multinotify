#!/usr/bin/perl

######
# Multinotify Desktop Client
# nchowning, 2011 - nathanchowning@me.com
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

$data = "receive";
print $socket "$data\n";

while(1)
{
    # Store the received data (from the server) in $received and split
    # it into @receivear
    $received = <$socket>;
    chomp($received);
    my @receivear = split(",,",$received);

    # Check to see what the server has sent
    if ($received eq "hello_client")
    {
        my $data = "hello_server";
        print $socket "$data\n";
    }
    elsif ($receivear[0] eq "mess")
    {
        print "$receivear[1]: $receivear[2]\n";
        notify($receivear[1], $receivear[2]);
    }
    else
    {
        sleep(1);
    }

    # Set this to 2 so it will only enter the last else case unless updated
    $receivedar[0] = 2;
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
