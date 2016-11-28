#!/usr/bin/env sh

echo "# Installing mod remotely..."

echo "Stopping server..."
curl -X POST -v --cookie "SessionID=298471480324572" --data "stop_server=Stop" -H "Origin: http://46.105.83.26:4242" http://46.105.83.26:4242/index.html > /dev/null

echo "Uploading new mod..."
curl -T FS17_seasons.zip ftp://$FTPUSER:$FTPPASS@ftp-3.verygames.net/games/FarmingSimulator17/mods/

echo "Starting server..."
curl -X POST -v --cookie "SessionID=298471480324572" --data "game_name=Bear%27s+Farm&admin_password=BigVaraBoss&game_password=SimpleFarmHand&savegame=2&map_start=default_Map01&difficulty=2&dirt_interval=2&matchmaking_server=2&mp_language=en&auto_save_interval=180&stats_interval=360&pause_game_if_empty=on&start_server=Start" -H "Origin: http://46.105.83.26:4242" http://46.105.83.26:4242/index.html > /dev/null
