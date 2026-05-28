<?php
$config_file='/etc/loadwatch_config.json';
$config=file_exists($config_file)?json_decode(file_get_contents($config_file),true):[];
?>
<html><body>
<h2>LoadWatch Pro v2</h2>
<form method='post' action='save.php'>
Threshold: <input name='threshold' value='<?= $config['threshold']??90 ?>'><br>
Duration: <input name='duration' value='<?= $config['duration']??5 ?>'><br>
Email: <input name='email' value='<?= $config['email']??"" ?>'><br>
Slack: <input name='slack' value='<?= $config['alerts']['slack_webhook']??"" ?>'><br>
Telegram Bot: <input name='telegram_bot'><br>
Chat ID: <input name='telegram_chat'><br>
Smart Recovery: <input type='checkbox' name='smart' <?= (!empty($config['smart_action']))?'checked':'' ?>><br>
<input type='submit' value='Save'>
</form>
</body></html>