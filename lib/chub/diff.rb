class Chub


  ##
  # Creates simple diffs as formatted strings or arrays, from two strings or
  # data objects.

  class Diff

    ##
    # Format diff with ascii

    class AsciiFormat

      def self.lines line_nums, col_width
        out =
          [*line_nums].map do |lnum|
            lnum.to_s.rjust col_width
          end.join "|"

        "#{out} "
      end


      def self.deleted str
        "- #{str}"
      end


      def self.added str
        "+ #{str}"
      end


      def self.common str
        "  #{str}"
      end
    end


    ##
    # Format diff with ascii

    class ColorFormat

      def self.require_win_color
        begin
          require 'Win32/Console/ANSI'
        rescue LoadError
          puts "Warning: You must gem install win32console to use color"
        end
      end


      def self.lines line_nums, col_width
        require_win_color if Diff.windows?

        out =
          [*line_nums].map do |lnum|
            lnum.to_s.rjust col_width
          end.join "\033[32m"

        "\033[7;31m#{out}\033[0m "
      end


      def self.deleted str
        require_win_color if Diff.windows?
        "\033[31m#{str}\033[0m"
      end


      def self.added str
        require_win_color if Diff.windows?
        "\033[32m#{str}\033[0m"
      end


      def self.common str
        str
      end
    end


    ##
    # Creates a new diff from two data objects.

    def self.new_from_data data1, data2, options={}
      new ordered_data_string(data1, options[:struct]),
          ordered_data_string(data2, options[:struct])
    end


    ##
    # Returns a data string that is diff-able, meaning sorted by
    # Hash keys when available.

    def self.ordered_data_string data, struct_only=false, indent=0
      case data

      when Hash
        output = "{\n"

        data_values =
          data.map do |key, value|
            pad = " " * indent
            subdata = ordered_data_string value, struct_only, indent + 1
            "#{pad}#{key.inspect} => #{subdata}"
          end

        output << data_values.sort.join(",\n") << "\n" unless data_values.empty?
        output << "#{" " * indent}}"

      when Array
        output = "[\n"

        data_values =
          data.map do |value|
            pad = " " * indent
            "#{pad}#{ordered_data_string value, struct_only, indent + 1}"
          end

        output << data_values.join(",\n") << "\n" unless data_values.empty?
        output << "#{" " * indent}]"

      else
        return data.inspect unless struct_only
        return "Boolean" if data == true || data == false
        data.class
      end
    end


    ##
    # Adds line numbers to each lines of a String.

    def self.insert_line_nums str, formatter=nil
      format = Diff.formatter formatter

      out   = ""
      width = str.lines.count.to_s.length

      str.split("\n").each_with_index do |line, i|
        out << "#{format.lines(i+1, width)}#{line}\n"
      end

      out
    end


    ##
    # Returns a formatter from a symbol or string. Returns nil if not found.

    def self.formatter name
      return ColorFormat if name == :color_diff
      AsciiFormat
    end


    ##
    # Check if we're on the windows platform.

    def self.windows?
      !!(RUBY_PLATFORM.downcase =~ /mswin|mingw|cygwin/)
    end


    attr_accessor :str1, :str2, :char, :formatter, :show_lines

    def initialize str1, str2, options={}
      @str1       = str1
      @str2       = str2
      @char       = options[:char] || /\r?\n/
      @diff_ary   = nil
      @show_lines = options[:show_lines]
      @formatter  =
        self.class.formatter(options[:diff_format]) || AsciiFormat
    end


    ##
    # Returns a diff array with the following format:
    #   str1 = "match1\nmatch2\nstr1 val"
    #   str1 = "match1\nin str2\nmore str2\nmatch2\nstr2 val"
    #
    #   Diff.new(str1, str2).create_diff
    #   ["match 1",
    #    [[], ["in str2", "more str2"]],
    #    "match 2",
    #    [["str1 val"], ["str2 val"]]]
    #
    # If a block is given, will pass it both sides of the diff as
    # an array, or the string matched if there is no diff.

    def create_diff
      diff_ary = []
      sub_diff = nil

      arr1 = @str1.split @char
      arr2 = @str2.split @char

      until arr1.empty? && arr2.empty?
        item1, item2 = arr1.shift, arr2.shift

        if item1 == item2
          if sub_diff
            yield sub_diff if block_given?
            diff_ary << sub_diff
            sub_diff = nil
          end

          yield item1 if block_given?
          diff_ary << item1
          next
        end

        match1 = arr1.index item2
        match2 = arr2.index item1

        if match1
          diff_ary.concat diff_match(item1, match1, arr1, 0, sub_diff)
          sub_diff = nil

        elsif match2
          diff_ary.concat diff_match(item2, match2, arr2, 1, sub_diff)
          sub_diff = nil

        elsif !item1.nil? || !item2.nil?
          sub_diff ||= [[],[]]
          sub_diff[0] << item1 if item1
          sub_diff[1] << item2 if item2
        end
      end

      if sub_diff
        yield sub_diff if block_given?
        diff_ary << sub_diff
      end

      diff_ary
    end


    ##
    # Create a diff from a match.

    def diff_match item, match, arr, side, sub_diff
      sub_diff ||= [[],[]]

      index = match - 1
      added = [item]
      added.concat arr.slice!(0..index) if index >= 0

      sub_diff[side].concat(added)
      [sub_diff, arr.shift]
    end


    ##
    # Returns a formatted output as a string.
    # Supported options are:
    # :join_char:: String - The string used to join lines; default "\n"
    # :show_lines:: Boolean - Insert line numbers or not; default @show_lines
    # :formatter:: Object - The formatter to use; default @formatter

    def formatted options={}
      options = {
        :join_char  => "\n",
        :show_lines => @show_lines,
        :formatter  => @formatter
      }.merge options

      format = options[:formatter]

      line1 = line2 = 0

      lines1 = @str1.lines.count
      lines2 = @str2.lines.count

      width = (lines1 > lines2 ? lines1 : lines2).to_s.length

      diff_array.map do |item|
        case item
        when String
          line1 = line1.next
          line2 = line2.next

          lines = format.lines [line1, line2], width if options[:show_lines]
          "#{lines}#{format.common item}"

        when Array
          item = item.dup

          item[0] = item[0].map do |str|
            line1 = line1.next
            lines = format.lines [line1, nil], width if options[:show_lines]
            "#{lines}#{format.deleted str}"
          end

          item[1] = item[1].map do |str|
            line2 = line2.next
            lines = format.lines [nil, line2], width if options[:show_lines]
            "#{lines}#{format.added str}"
          end

          item
        end
      end.flatten.join options[:join_char]
    end


    ##
    # Returns the number of diffs found.

    def count
      diff_array.select{|i| Array === i }.length
    end


    ##
    # Returns the cached diff array when available, otherwise creates it.

    def diff_array
      @diff_ary ||= create_diff
    end

    alias to_a diff_array


    ##
    # Returns a diff string with the default format.

    def to_s
      formatted
    end
  end
end

