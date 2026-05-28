#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use File::Slurp;

my $config_file = '/etc/load_monitor_config.json';
my $log_file = '/var/log/load_monitor.log';
my $state_file = '/var/run/load_monitor_state.json';

# Load configuration
my $config = load_config();
exit 0 unless $config->{monitor_enabled};

# Get current load
my $current_load = get_load_average();
my $load_percentage = calculate_load_percentage($current_load);

# Load previous state
my $state = load_state();

# Check if threshold exceeded
if ($load_percentage >= $config->{load_threshold}) {
    # Increment exceed counter
    $state->{consecutive_exceeds}++;
    $state->{first_exceed_time} ||= time();
    
    # Check if duration threshold met
    my $exceed_duration = (time() - $state->{first_exceed_time}) / 60;
    
    if ($exceed_duration >= $config->{time_duration} && !$state->{action_taken}) {
        # Take action
        take_action($config, $load_percentage);
        $state->{action_taken} = 1;
        $state->{last_action_time} = time();
        
        write_log("Action taken: Load $load_percentage% exceeded threshold for $exceed_duration minutes");
    }
} else {
    # Reset state if load is normal
    $state->{consecutive_exceeds} = 0;
    $state->{first_exceed_time} = 0;
    $state->{action_taken} = 0;
}

# Save state
save_state($state);

sub load_config {
    if (-f $config_file) {
        my $json = read_file($config_file);
        return decode_json($json);
    }
    return {
        load_threshold => 80,
        time_duration => 5,
        action => 'email',
        email => 'root@localhost',
        monitor_enabled => 0,
        check_interval => 60
    };
}

sub get_load_average {
    open(my $fh, '<', '/proc/loadavg') or return 0;
    my $load = <$fh>;
    close($fh);
    my @loads = split(/\s+/, $load);
    return $loads[0];
}

sub calculate_load_percentage {
    my $load = shift;
    my $cpu_cores = get_cpu_cores();
    return ($load / $cpu_cores) * 100;
}

sub get_cpu_cores {
    open(my $fh, '<', '/proc/cpuinfo') or return 1;
    my $cores = 0;
    while (<$fh>) {
        $cores++ if /^processor\s*:/;
    }
    close($fh);
    return $cores || 1;
}

sub load_state {
    if (-f $state_file) {
        my $json = read_file($state_file);
        return decode_json($json);
    }
    return {
        consecutive_exceeds => 0,
        first_exceed_time => 0,
        action_taken => 0,
        last_action_time => 0
    };
}

sub save_state {
    my $state = shift;
    write_file($state_file, encode_json($state));
}

sub take_action {
    my ($config, $load) = @_;
    
    my $action = $config->{action};
    
    if ($action eq 'email' || $action eq 'both') {
        send_alert_email($config, $load);
    }
    
    if ($action eq 'restart_apache' || $action eq 'both') {
        system('/scripts/restartsrv_apache');
        write_log("Apache restarted due to high load");
    }
    
    if ($action eq 'restart_mysql' || $action eq 'both') {
        system('/scripts/restartsrv_mysql');
        write_log("MySQL restarted due to high load");
    }
}

sub send_alert_email {
    my ($config, $load) = @_;
    
    my $subject = "High Load Alert - Action Taken";
    my $message = "Server load has reached $load% of capacity\n";
    $message .= "Threshold: $config->{load_threshold}%\n";
    $message .= "Duration: $config->{time_duration} minutes\n";
    $message .= "Action Taken: $config->{action}\n";
    $message .= "Time: " . localtime() . "\n";
    $message .= "Please check your server immediately.\n";
    
    open(my $mail, '| /usr/sbin/sendmail -t') or return;
    print $mail "To: $config->{email}\n";
    print $mail "From: load-monitor@localhost\n";
    print $mail "Subject: $subject\n";
    print $mail "Content-Type: text/plain\n\n";
    print $mail $message;
    close($mail);
    
    write_log("Alert email sent to $config->{email}");
}

sub write_log {
    my $message = shift;
    my $timestamp = localtime();
    open(my $fh, '>>', $log_file) or return;
    print $fh "[$timestamp] $message\n";
    close($fh);
}
