math.randomseed(Rdseed())

local challenges = {
  {
    question = 'What is four plus seven?',
    answer = '11'
  },
  {
    question = 'If you multiply three by five, what do you get?',
    answer = '15'
  },
  {
    question = 'What is twelve minus five?',
    answer = '7'
  },
  {
    question = 'What\'s half of twenty-four?',
    answer = '12'
  },
  {
    question = 'How many days are in a week, plus two?',
    answer = '9'
  },
  {
    question = 'What color is the sky on a clear day?',
    answer = 'blue'
  },
  {
    question = 'How many legs does a cat have?',
    answer = '4'
  },
  {
    question = 'What planet do we live on?',
    answer = 'earth'
  },
  {
    question = 'What comes after Wednesday in the week?',
    answer = 'thursday'
  },
  {
    question = 'What number comes after fifty-five?',
    answer = '56'
  },
  {
    question = 'What is the first letter of \'registration\'?',
    answer = 'r'
  },
  {
    question = 'Type the word \'human\' backwards.',
    answer = 'namuh'
  },
  {
    question = 'What is the last letter in \'account\'?',
    answer = 't'
  },
  {
    question = 'Count the number of letters in the word \'security\'.',
    answer = '8'
  },
  {
    question = 'If \'A\' is 1, \'B\' is 2, what position is \'D\' in the alphabet?',
    answer = '4'
  }
}

return {
  getRandom = function()
    local idx = math.random(1, #challenges)
    return challenges[idx], idx
  end,

  validate = function(answer, challenge_idx)
    local challenge = challenges[challenge_idx]

    if not challenge then
      return false
    end

    answer = string.lower(answer)
    return answer == string.lower(challenge.answer)
  end
}