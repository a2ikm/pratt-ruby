#!/usr/bin/env ruby

class Token
  attr_reader :type, :literal

  def initialize(type, literal)
    @type = type
    @literal = literal
  end
end

class Lexer
  attr_reader :source, :position, :read_position, :ch

  def initialize(source)
    @source = source
    @position = 0
    @read_position = 0
    advance
  end

  def next_token
    token = nil

    case @ch
    when "+"
      token = Token.new(:plus, @ch)
    when "-"
      token = Token.new(:minus, @ch)
    when "*"
      token = Token.new(:asterisk, @ch)
    when "/"
      token = Token.new(:slash, @ch)
    when "%"
      token = Token.new(:percentage, @ch)
    when nil
      token = Token.new(:eof, "")
    else
      if digit?(@ch)
        return Token.new(:int, read_number)
      else
        token = Token.new(:illegal, @ch)
      end
    end

    advance
    token
  end

  private

  def read_number
    pos = @position
    while digit?(@ch)
      advance
    end
    @source[pos...@position]
  end

  def digit?(ch)
    /^[0-9]$/.match?(ch)
  end

  def advance
    if @read_position >= @source.length
      @ch = nil
    else
      @ch = @source[@read_position]
    end
    @position = @read_position
    @read_position += 1
  end
end

class IntegerLiteral
  attr_reader :token, :value

  def initialize(token, value)
    @token = token
    @value = value
  end
end

class PrefixExpression
  attr_reader :token, :op, :right

  def initialize(token, op, right)
    @token = token
    @op = op
    @right = right
  end
end

class InfixExpression
  attr_reader :token, :left, :op, :right

  def initialize(token, left, op, right)
    @token = token
    @left = left
    @op = op
    @right = right
  end
end

class Parser
  LOWEST  = 0
  SUM     = 1
  MUL     = 2
  PREFIX  = 3

  PRECEDENCES = {
    plus:     SUM,
    minus:    SUM,
    slash:    MUL,
    asterisk: MUL,
  }.freeze

  def initialize(lexer)
    @lexer = lexer
    @current = nil
    @peek = nil
    advance
    advance

    @prefix_parsers = {}
    register_prefix(:int, :parse_integer_literal)
    register_prefix(:minus, :parse_prefix_expression)

    @infix_parsers = {}
    register_infix(:plus, :parse_infix_expression)
    register_infix(:minus, :parse_infix_expression)
    register_infix(:slash, :parse_infix_expression)
    register_infix(:asterisk, :parse_infix_expression)
  end

  def parse
    parse_expression(LOWEST)
  end

  private

  def parse_expression(precedence)
    prefix = @prefix_parsers[@current.type]
    if prefix.nil?
      return nil
    end

    left = send(prefix)

    while !peek?(:eof) && precedence < peek_precedence
      infix = @infix_parsers[@peek.type]
      if infix.nil?
        return left
      end

      advance
      left = send(infix, left)
    end

    left
  end

  def parse_integer_literal
    value = Integer(@current.literal) rescue nil
    if value.nil?
      return nil
    end

    IntegerLiteral.new(@current, value)
  end

  def parse_prefix_expression
    token = @current
    op = token.literal
    advance
    PrefixExpression.new(token, op, parse_expression(PREFIX))
  end

  def parse_infix_expression(left)
    token = @current
    op = token.literal
    precedence = current_precedence
    advance
    InfixExpression.new(token, left, op, parse_expression(precedence))
  end

  def register_prefix(type, method_name)
    @prefix_parsers[type] = method_name
  end

  def register_infix(type, method_name)
    @infix_parsers[type] = method_name
  end

  def current_precedence
    if p = PRECEDENCES[@current&.type]
      return p
    end

    LOWEST
  end

  def peek_precedence
    if p = PRECEDENCES[@peek&.type]
      return p
    end

    LOWEST
  end

  def current?(type)
    @current&.type == type
  end

  def peek?(type)
    @peek&.type == type
  end

  def expect(type)
    if peek?(type)
      advance
      true
    else
      false
    end
  end

  def advance
    @current = @peek
    @peek = @lexer.next_token
  end
end

class Evaluator
  def evaluate(node)
    case node
    when IntegerLiteral
      node.value
    when PrefixExpression
      case node.op
      when "-"
        -evaluate(node.right)
      else
        raise "unexpected prefix operator: #{node.op.inspect}"
      end
    when InfixExpression
      left = evaluate(node.left)
      right = evaluate(node.right)
      case node.op
      when "+"
        left + right
      when "-"
        left - right
      when "*"
        left * right
      when "/"
        left / right
      else
        raise "unexpected infix operator: #{node.op.inspect}"
      end
    else
      raise "unexpected node: #{node.inspect}"
    end
  end
end

def pratt(source)
  lexer = Lexer.new(source)
  parser = Parser.new(lexer)
  evaluator = Evaluator.new
  evaluator.evaluate(parser.parse)
end

if $0 == __FILE__
  puts pratt($stdin.read)
end
