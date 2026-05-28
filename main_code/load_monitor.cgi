#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use Cpanel::JSON::XS qw(encode_json decode_json);
use Cpanel::LoadFile ();

# Initialize CGI
my $cgi = CGI->new;
print $cgi->header('text/html; charset=utf-8');

# Check if user has root access
if ($ENV{'REMOTE_USER'} ne 'root') {
    print "Only root user can access this plugin";
    exit 1;
}

# Get action parameter
my $action = $cgi->param('action') || 'show';

# Handle different actions
if ($action eq 'save') {
    save_settings($cgi);
} elsif ($action eq 'get_status') {
    get_status();
} elsif ($action eq 'manual_action') {
    manual_action($cgi);
} else {
    show_interface();
}

sub show_interface {
    my $settings = load_settings();
    my $status = get_current_status();
    
    # Read template
    my $template_path = '/usr/local/cpanel/base/frontend/paper_lantern/load_monitor/load_monitor.html.tt';
    my $template = Cpanel::LoadFile::load_if_exists($template_path);
    
    # Replace template variables
    $template =~ s/\[% settings.load_threshold %\]/$settings->{load_threshold}/g;
    $template =~ s/\[% settings.time_duration %\]/$settings->{time_duration}/g;
    $template =~ s/\[% settings.action %\]/$settings->{action}/g;
    $template =~ s/\[% settings.email %\]/$settings->{email}/g;
    $template =~ s/\[% status.current_load %\]/$status->{current_load}/g;
    $template =~ s/\[% status.status_message %\]/$status->{status_message}/g;
    
    print $template;
}

sub save_settings {
    my $cgi = shift;
    
    my $settings = {
        load_threshold => $cgi->param('load_threshold') || 80,
        time_duration => $cgi->param('time_duration') || 5,
        action => $cgi->param('action_type') || 'email',
        email => $cgi->param('email') || 'root@localhost',
        monitor_enabled => $cgi->param('monitor_enabled') || 0,
        check_interval => $cgi->param('check_interval') || 60
    };
    
    # Validate settings
    if ($settings->{load_threshold} < 1 || $settings->{load_threshold} > 1000) {
        print "Invalid load threshold";
        return;
    }
    
    # Save to config file
    my $config_file = '/etc/load_monitor_config.json';
    open(my $fh, '>', $config_file) or die "Cannot open $config_file: $!";
    print $fh encode_json($settings);
    close($fh);
    
    # Update crontab
    update_crontab($settings);
    
    # Return to interface
    print "<script>window.location.href='load_monitor.cgi?action=show&saved=1';</script>";
}

sub update_crontab {
    my $settings = shift;
    
    my $cron_file = '/etc/cron.d/load_monitor';
    
    if ($settings->{monitor_enabled}) {
        my $interval = $settings->{check_interval};
        open(my $fh, '>', $cron_file) or die "Cannot create $cron_file: $!";
        print $fh "*/$interval * * * * root /usr/local/cpanel/base/frontend/paper_lantern/load_monitor/scripts/monitor_load.pl\n";
        close($fh);
    } else {
        unlink($cron_file) if -f $cron_file;
    }
}

sub load_settings {
    my $config_file = '/etc/load_monitor_config.json';
    
    if (-f $config_file) {
        open(my $fh, '<', $config_file);
        my $json = do { local $/; <$fh> };
        close($fh);
        return decode_json($json);
    }
    
    # Default settings
    return {
        load_threshold => 80,
        time_duration => 5,
        action => 'email',
        email => 'root@localhost',
        monitor_enabled => 0,
        check_interval => 60
    };
}

sub get_current_status {
    # Get current load average
    my $load = get_load_average();
    
    my $status = {
        current_load => $load,
        status_message => ''
    };
    
    if ($load > 5) {
        $status->{status_message} = "CRITICAL: High load detected!";
    } elsif ($load > 3) {
        $status->{status_message} = "WARNING: Load is elevated";
    } else {
        $status->{status_message} = "Normal";
    }
    
    return $status;
}

sub get_load_average {
    open(my $fh, '<', '/proc/loadavg') or return 0;
    my $load = <$fh>;
    close($fh);
    
    my @loads = split(/\s+/, $load);
    return $loads[0];
}

sub get_status {
    my $status = get_current_status();
    print encode_json($status);
}

sub manual_action {
    my $cgi = shift;
    my $action = $cgi->param('action_type');
    
    if ($action eq 'restart_apache') {
        system('/scripts/restartsrv_apache');
        print "Apache restarted successfully";
    } elsif ($action eq 'restart_mysql') {
        system('/scripts/restartsrv_mysql');
        print "MySQL restarted successfully";
    } elsif ($action eq 'send_email') {
        send_alert_email(get_current_status()->{current_load});
        print "Alert email sent";
    }
}

sub send_alert_email {
    my $load = shift;
    my $settings = load_settings();
    
    my $subject = "High Load Alert on server";
    my $message = "Server load has reached $load\n";
    $message .= "Threshold: $settings->{load_threshold}%\n";
    $message .= "Time: " . localtime() . "\n";
    
    open(my $mail, '| /usr/sbin/sendmail -t') or return;
    print $mail "To: $settings->{email}\n";
    print $mail "From: root@localhost\n";
    print $mail "Subject: $subject\n";
    print $mail "Content-Type: text/plain\n\n";
    print $mail $message;
    close($mail);
}
