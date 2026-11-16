#!/usr/bin/env bash

#Asking for first number
read -p "Enter your first number: " first
read -p "Enter the second number: " second
read -p "Enter the operator: " operator
#No error checking and it does not include decimals, very basic

output=$(( "$first""$operator""$second" ))
echo "$output"
