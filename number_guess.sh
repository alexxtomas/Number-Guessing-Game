#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"


echo "Enter your username:"
read USERNAME

# Fetch the username and user_id from the database
USERNAME_RESULT=$($PSQL "SELECT username FROM players WHERE username='$USERNAME'")
USER_ID_RESULT=$($PSQL "SELECT user_id FROM players WHERE username='$USERNAME'")

if [[ -z $USERNAME_RESULT ]]; then
  # Greet new player if username does not exist in the database
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here.\n"
  # Insert new player into the database
  INSERT_USERNAME_RESULT=$($PSQL "INSERT INTO players(username) VALUES ('$USERNAME')")
else
  # If the username exists, fetch the number of games played and the best game guess count
  GAMES_PLAYED=$($PSQL "SELECT COUNT(game_id) FROM games LEFT JOIN players USING(user_id) WHERE username='$USERNAME'")
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games LEFT JOIN players USING(user_id) WHERE username='$USERNAME'")

  # Print the player's statistics
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate a secret number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESS_COUNT=1  # Start at 1 because the first guess is counted

# Prompt for the user's first guess
echo "Guess the secret number between 1 and 1000:"
read USER_GUESS

# Loop until the guess is correct
until [[ $USER_GUESS -eq $SECRET_NUMBER ]]; do
  if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]; then
    # If input is not a valid integer
    echo -e "\nThat is not an integer, guess again:"
    read USER_GUESS
  else
    if [[ $USER_GUESS -lt $SECRET_NUMBER ]]; then
      # If the guess is lower than the secret number
      echo "It's higher than that, guess again:"
      read USER_GUESS
    elif [[ $USER_GUESS -gt $SECRET_NUMBER ]]; then
      # If the guess is higher than the secret number
      echo "It's lower than that, guess again:"
      read USER_GUESS
    fi
  fi
  # Increment the guess count
  ((GUESS_COUNT++))
done

# Once the user guesses the correct number, record the game
USER_ID_RESULT=$($PSQL "SELECT user_id FROM players WHERE username='$USERNAME'")
INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, secret_number, number_of_guesses) VALUES ($USER_ID_RESULT, $SECRET_NUMBER, $GUESS_COUNT)")

# Congratulate the user
echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
