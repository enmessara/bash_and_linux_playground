#!/usr/bin/env bash

echo "Welcome to number guessing game..."
sleep 0.3
echo "Guess a number between 1-20"
sleep 0.3
min=1
max=20

rand=$(( RANDOM % (max - min + 1) + min))

while true; do
    read -rp "Guess a number: " user_guess
    if [[ "$user_guess" == $rand ]]; then
        echo "Congratulations! You guessed right!"
        exit 0
    else
        if [[ "$user_guess" > $rand ]]; then
            echo "Wrong! The answer is less than $user_guess"
        else
            echo "Wrong! The answer is greater than $user_guess"
        fi
    fi
done
