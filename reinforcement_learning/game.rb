# our game is a “catch the cheese” console game where the player P must move to
# catch the cheese C without falling into the pit O. The player gets one point of
# each cheese he finds and minus one point for every time he falls into the pit.
# The game ends if the user gets either 5 points or -5 points. This gif shows a
# human player playing the game.

#S = 12 states
#A = 2 (right/left)

#Q Table:

#States	Action: Left	Action: Right
#0	      0.2	          0.6
#1	     -0.6	          0.6
#2	     -0.4	          0.5
#3	     -0.2	          0.3
#4	     -0.1	          0.3
#5	      0	            0.2
#6	      0	            0.5
#7	      0.1	          0.6
#8	      0.3	          0.8
#9	      0.2	          1
#10	    1	            0.5
#11	    0.6	          0.2

#Step 1: Initialize Q table with random values
#Step 2: While playing the game execute the following loop
#Step 2.a: Generate random number between 0 and 1 – if number is larger than the threshold e select random action, otherwise select action with the highest possible reward based on state and Q-table
#Step 2.b: Take action from step 2.a
#Step 2.c: Observe reward r after taking action
#Step 2.d: Update Q table based on the reward r using the formula: http://www.practicalai.io/teaching-ai-play-simple-game-using-q-learning/

require 'io/console'

class Player
  attr_accessor :x

  def initialize
    @x = 0
  end

  def get_input
    input = STDIN.getch
    if input == 'a'
      return :left
    elsif input == 'd'
      return :right
    elsif input == 'q'
      exit
    end
    return :nothing
  end
end


class Game
  attr_accessor :score, :map_size

  def initialize player
    @run = 0
    @map_size = 12
    @start_position = 3
    @player = player
    reset

    # Clear the console
    puts "\e[H\e[2J"

  end

  def reset
    @player.x = @start_position
    @cheese_x = 10
    @pit_x = 0
    @score = 0
    @run += 1
    @moves = 0
  end

  def run
    while @score < 5 && @score > -5
      draw
      gameloop
      @moves += 1
    end

    # Draw one last time to update the
    draw

    if @score >= 5
      puts "  You win in #{@moves} moves!"
    else
      puts "  Game over"
    end

  end

  def gameloop
    move = @player.get_input
    if move == :left
      @player.x = @player.x > 0 ? @player.x-1 : @map_size-1;
    elsif move == :right
      @player.x = @player.x < @map_size-1 ? @player.x+1 : 0;
    end

    if @player.x == @cheese_x
      @score += 1
      @player.x = @start_position
    end

    if @player.x == @pit_x
      @score -= 1
      @player.x = @start_position
    end
  end

  def draw
    # Compute map line
    map_line = @map_size.times.map do |i|
      if @player.x == i
        'P'
      elsif @cheese_x == i
        'C'
      elsif @pit_x == i
        'O'
      else
        '='
      end
    end
    map_line = "\r##{map_line.join}# | Score #{@score} | Run #{@run}"

    # Draw to console
    # use printf because we want to update the line rather than print a new one
    printf("%s", map_line)
  end
end

class QLearningPlayer
  attr_accessor :x, :game

  def initialize
    @x = 0
    @actions = [:left, :right]
    @first_run = true

    @learning_rate = 0.2
    @discount = 0.9
    @epsilon = 0.9

    @r = Random.new
  end

  def initialize_q_table
    # Initialize q_table states by actions
    @q_table = Array.new(@game.map_size){ Array.new(@actions.length) }

    # Initialize to random values
    @game.map_size.times do |s|
      @actions.length.times do |a|
        @q_table[s][a] = @r.rand
      end
    end
  end

  def get_input
    # Pause to make sure humans can follow along
    sleep 0.05

    if @first_run
      # If this is first run initialize the Q-table
      initialize_q_table
      @first_run = false
    else
      # If this is not the first run
      # Evaluate what happened on last action and update Q table
      # Calculate reward
      r = 0 # default is 0
      if @old_score < @game.score
        r = 1 # reward is 1 if our score increased
      elsif @old_score > @game.score
        r = -1 # reward is -1 if our score decreased
      end

      # Our new state is equal to the player position
      @outcome_state = @x
      @q_table[@old_state][@action_taken_index] = @q_table[@old_state][@action_taken_index] + @learning_rate * (r + @discount * @q_table[@outcome_state].max - @q_table[@old_state][@action_taken_index])
    end

    # Capture current state and score
    @old_score = @game.score
    @old_state = @x

    # Chose action based on Q value estimates for state
    if @r.rand > @epsilon
      # Select random action
      @action_taken_index = @r.rand(@actions.length).round
    else
      # Select based on Q table
      s = @x
      @action_taken_index = @q_table[s].each_with_index.max[1]
    end

    # Take action
    return @actions[@action_taken_index]
  end


  def print_table
    @q_table.length.times do |i|
      puts @q_table[i].to_s
    end
  end
end


#puts "Run normal"
#p = Player.new
#g = Game.new( p )
#g.run


puts "Run q game"
p = QLearningPlayer.new
g = Game.new( p )
p.game = g

10.times do
  g.run
  g.reset
end

p.print_table
puts ""

