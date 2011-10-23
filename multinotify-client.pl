#!/usr/bin/perl

######
# Multinotify Desktop Client
# nchowning, 2011 - nathanchowning@me.com
######

# Set the app name and load the socket module
use constant APP_NAME => 'multinotify-client';
use IO::Socket::INET;

my $IPADDRESS = 'IP ADDRESS IN HERE';
my $PORT = 'PORT IN HERE';
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

while(<$socket>)
{
#    my ($username,$message);

    # Store the username in $username and chomp it to remove the newline
    chomp($username = $_);

    # Be courteous and tell the server "thanks"
    $data = "thanks";
    print $socket "$data\n";

    # Store the message in $message and chomp it to remove the newline
    chomp($message = <$socket>);

    # Send the username and message to notify
    notify($username, $message);
    print "$username: $message\n";

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
