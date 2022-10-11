require "toml"

# stolen from https://tomdriven.dev/ruby/2015/09/08/calculating-a-percentage-in-ruby-elegantly.html
struct Number
  def percent_of(n)
    self.to_f / n.to_f * 100.0
  end
end

quiz_questions_directory   = "./quiz_questions/"
number_of_questions_to_ask = 3


#############################################
# Sanity checks
#############################################

# Check if the quiz_questions_directory directory exists
if ! Dir.exists?(quiz_questions_directory)
  abort "The \"#{quiz_questions_directory}\" directory doesn't exist"
end

# Check if the quiz_questions_directory is empty
if Dir.empty?(quiz_questions_directory)
  abort "The \"#{quiz_questions_directory}\" directory is empty - please add some .toml files in it!"
end

#############################################
# Create an array to store the TOML files in
#############################################

toml_array_of_questions = Array(TOML::Type).new

#############################################
# Load questions from the ../quiz_questions
# directory
#############################################

puts "INFO: Loading quiz files ..."
files_inside_quiz_questions_directory = Dir.new(quiz_questions_directory)
files_inside_quiz_questions_directory.each_child do |filename|
  unless filename.ends_with?(".toml") 
    puts "The file \"#{filename}\" does not end with .toml - skipping"
    next
  end

  begin
    file_contents = File.read("#{quiz_questions_directory}#{filename}")
    toml = TOML.parse(file_contents)
  rescue exception
    abort "Something went wrong while trying to read the file \"#{filename}\".\nThe exception message is:\n#{exception}" 
  end
  puts "Successfully loaded the file \"#{filename}\"" 

  # check if all of those keys are present in each quiz file
  array_of_keys = [ "correct_answer", "question", "possible_answers"] 
  array_of_keys.each do |key|
    unless toml.as(Hash).has_key?(key)
      abort "The file #{quiz_questions_directory}#{filename} does not have a \"#{key}\" key"
    end
  end

  toml_array_of_questions << toml
end

if toml_array_of_questions.size == 0
  abort "Sorry, I couldn't load any questions to quiz you on :("
end

puts "INFO: #{toml_array_of_questions.size} questions loaded"

#############################################
# Shuffle the loaded questions 
#############################################

toml_array_of_questions = toml_array_of_questions.sample(number_of_questions_to_ask)
toml_array_of_questions.shuffle!

#############################################
# Start asking questions
#############################################

number_of_correct_answers = 0
total_number_of_questions = toml_array_of_questions.size

toml_array_of_questions.size.times do 
  question_data      = toml_array_of_questions.pop.as(Hash)
  # we load the questions from the TOML as an array and while we're at it, we shuffle them too! :)
  array_of_questions = question_data["possible_answers"].as(Array).shuffle!
  correct_answer     = question_data["correct_answer"]
  question           = question_data["question"]
  puts "==============================================="
  puts question
  array_of_questions.each_with_index(1) do |possible_answer, index|
    puts "#{index}. #{possible_answer}"
  end
  while true
    print "What is your choice ? "
    begin
      # check if the input can be converted to an integer
      input = gets.not_nil!.to_i
      # check if the integer is within our range
      if (1..(array_of_questions.size)).includes?(input)
        # if you got here that means that the number is an integer and it is
	# within our range, so break out of this while true loop
	break
      else
        puts "#{input} is outside of range - please choose between 1 and #{array_of_questions.size}"
      end
    rescue
      puts "that wasn't a valid int."
    end
  end
  if array_of_questions[input-1] == correct_answer
    puts "Correct!"
    number_of_correct_answers = number_of_correct_answers + 1
  else
    puts "Wrong answer, the correct answer is: \"#{correct_answer}\""
  end
end

puts "You got #{number_of_correct_answers} out of #{total_number_of_questions} correct (#{number_of_correct_answers.percent_of(total_number_of_questions).round(2)}%)"
