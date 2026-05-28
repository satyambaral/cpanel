<?php
$config=[
 'threshold'=>intval($_POST['threshold']),
 'duration'=>intval($_POST['duration']),
 'email'=>$_POST['email'],
 'smart_action'=>isset($_POST['smart']),
 'alerts'=>[
  'slack_webhook'=>$_POST['slack'],
  'telegram_bot_token'=>$_POST['telegram_bot'],
  'telegram_chat_id'=>$_POST['telegram_chat']
 ]
];
file_put_contents('/etc/loadwatch_config.json',json_encode($config,JSON_PRETTY_PRINT));
echo 'Saved';
?>