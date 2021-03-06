# The Project module includes methods for creating, loading and viewing projects
# as well as creating and editing tasks

# reference required gems
require 'tty-prompt'
require 'tty-table'
require 'time'
require 'rainbow'
# gem setup

$tasks = 0
$task_hash = Hash.new

module Project
  
    @@no_selection = true
    @@prompt = TTY::Prompt.new
    @@task_no = 0

    # Creates a new project    
    def Project.create()
          $project_name = @@prompt.collect do
            key(:filename).ask("Enter your project file name (No spaces or special characters excluding _)", validate: /^\w*$/, default: "untitled_project")
            key(:title).ask("Enter your Project Title", default: "Untitled Project")
          end
          #initiate YAML save here somehow        
    end

    def Project.load(filename)
    end

    # Views whichever project is loaded
    def Project.view
      to_do = []
      in_prog = []
      comp = []
      $task_hash.each {|key, value|
      if value[:status] == "To Do"
        to_do << key
      elsif value[:status] == "In Progress"
        in_prog << key
      else
        comp << key
      end
      }
      head = ["To Do", "In Progress", "Completed"]
      table_array = Array.new
      x = [to_do.length, in_prog.length, comp.length]
      x = x.max
      for i in 0..x-1 do
        table_array << [to_do[i], in_prog[i], comp[i]]
      end
      view_table = TTY::Table.new(head,table_array)
      system("clear")
      puts Rainbow("#{$project_name[:title]} - Project Overview").underline.red
      puts"\n"
      puts view_table.render(:unicode)
      end

    def Project.date_view
      puts "fucntionality not available yet, watch this space!"
    end

    # Creates a new Project Task
    def Project.new_task
      
      @@task_no += 1
      system("clear")
      # User input and validation(alphanumeric, underscore, dash & spaces) for task name
      task_name = @@prompt.ask("Enter the task's title", validate: /^[\w\-\s]+$/, default: "Task Number #{@@task_no}")

      # Select Task Status
      status = @@prompt.select("Select the Task's status") do |menu|
        menu.choice "To Do"
        menu.choice "In Progress"
        menu.choice "Completed"
      end

      # Sets default values for tasks
      desc = false
      due_date_time = false
      priority = "Normal"
      checklist = false
      tags = ["no tags"]
      comments = false

      # Collects Task data via user input
      yn = @@prompt.yes?("Would you like to include a Description?")
      if yn == true
        desc = @@prompt.multiline("Description?")  
      end
      yn = @@prompt.yes?("Would you like to include a Due Date?")
      if yn == true
        due_date_time = @@prompt.ask("Enter the task's due date and time eg. January 21st 2021 1pm or DD/MM/YYYY 13:00")
        due_date_time = Time.parse(due_date_time) # Converts string into time format, very flexible with input!
      end
      yn = @@prompt.yes?("Set Task priority? (if no, default is Normal)")
      if yn == true
        priority = @@prompt.select("Set Task Priority", %w(Low Normal High Critical))
      end
      yn = @@prompt.yes?("Add a checklist?")
      if yn == true
        checklist = Hash.new
      end
      while yn == true
        list_item = @@prompt.ask("Input checklist item", validate: /^[\w\-\s]+$/)
        checklist[list_item] = false
        yn = @@prompt.yes?("Add another checklist item?")
      end
      yn = @@prompt.yes?("Add a comment?")
      if yn == true
        comments = Hash.new
        comment = @@prompt.multiline("Input Task comment")
        comments[Time.new] = comment
      end
      yn = @@prompt.yes?("Add Tags")
      if yn == true
        tags = @@prompt.multiline("Input tags separated by a new line (enter/return)")
      end  
      $task_hash[task_name] = {status: status, description: desc, due: due_date_time, priority: priority, 
      checklist: checklist, tags: tags, comments: comments}
    end

    # Allows user to select a Task from a list of all tasks
    def Project.select_task
      begin
      tasks = Hash.new
      $task_hash.each_key {|key|
        tasks[key] = key
      }
      @@task = @@prompt.select("Select a Task", tasks, filter: true, per_page: 10)
      rescue NoMethodError
        puts "You do not have any tasks"
        return "error"
      end
    end


    # Selects and displays a task
    def Project.view_task
      begin
      Project.select_task
      system("clear")
      puts Rainbow("\n#{@@task} | #{$project_name[:title]}").underline.red
      puts Rainbow("\nStatus").blue + " - #{$task_hash[@@task][:status]}"
      puts Rainbow("\nPriority").blue + " - #{$task_hash[@@task][:priority]}"
      rescue NameError
        puts "You don't have any tasks to view, please create one"
        return "error"
      end
      if $task_hash[@@task][:due] != false
        puts Rainbow("\nDue Date").blue + " - #{$task_hash[@@task][:due].strftime("%d/%m/%Y")} at #{$task_hash[@@task][:due].strftime("%I:%M %p")}"
      end
      if $task_hash[@@task][:description] != false
        puts Rainbow("\nDescription:").underline.blue
      $task_hash[@@task][:description].each { |line|
        puts "#{line}"
      }
      end
      if $task_hash[@@task][:checklist] != false
        puts Rainbow("\nChecklist:").underline.blue #turn into table later
        table_array = Array.new
        $task_hash[@@task][:checklist].each { |item, status|
          table_array << [item, Project.yesno(status)]
        }
        view_table = TTY::Table.new(["Item", "Done"],table_array)
        puts view_table.render(:unicode, alignments: [:left, :center])
      end
      if $task_hash[@@task][:comments] != false
        puts Rainbow("\nComments:").blue.underline
        $task_hash[@@task][:comments].each { |date, comment|
          puts Rainbow("\n#{date.strftime("%d/%m/%Y")} at #{date.strftime("%I:%M %p")}").underline.green
          comment.each { |line|
            puts "#{line}"
          }
        }
        puts "\n"
      end
      puts Rainbow("\nTags:").underline.blue
      $task_hash[@@task][:tags].each {|tag| print"#{tag.chomp} "}
      #Menu/Edit/Delete/Comment options
    end
    
    # Selects a task if one hasn't been selected and allows user to edit task
    def Project.edit_task
      if @@no_selection == true
        Project.select_task
      end
      @@back_to_main = false
      while @@back_to_main == false
        system("clear")
        status = @@prompt.select("\n\n#{@@task} - Edit Task", per_page: 9, filter: true) do |menu|
        menu.choice "Change Title"
        menu.choice "Change Status"
        menu.choice "Change Description"
        menu.choice "Change Due Date"
        menu.choice "Change Task Priority"
        menu.choice "Add or Tick Checklist Item"
        menu.choice "Add Comment"
        menu.choice "Add Tags"
        menu.choice "Back to Main Menu"
        end
        
        if status == "Change Title"
          task_name = @@prompt.ask("Enter new task title", validate: /^[\w\-\s]+$/, default: "Task Number #{@@task_no}")
          $task_hash[task_name] = $task_hash.delete @@task
          @@task = task_name
        elsif status == "Change Status"
          status = @@prompt.select("Select the Task's new status") do |menu|
            menu.choice "To Do"
            menu.choice "In Progress"
            menu.choice "Completed"
          end
          $task_hash[@@task][:status] = status
        elsif status == "Change Description"
          desc = @@prompt.multiline("Enter New Description")
          $task_hash[@@task][:description] = desc
        elsif status == "Change Due Date"
          due_date_time = @@prompt.ask("Enter the task's due date and time eg. January 21st 2021 1pm or DD/MM/YYYY 13:00")
          due_date_time = Time.parse(due_date_time)
          $task_hash[@@task][:due] = due_date_time
        elsif status == "Change Task Priority"
          priority = @@prompt.select("Set Task Priority", %w(Low Normal High Critical))
          $task_hash[@@task][:priority] = priority
        elsif status == "Add or Tick Checklist Item"
          if $task_hash[@@task][:checklist] == false
            puts "No checklist error - will fix bug, for now add checklist item when creating task"
            return "No checklist error - will fix bug, for now add checklist item when creating task"
          end
          back_to_edit = false
          while back_to_edit == false
            system("clear")
            if $task_hash[@@task][:checklist] != false
              puts Rainbow("\nChecklist:").underline.blue #turn into table later
              table_array = Array.new
              $task_hash[@@task][:checklist].each { |item, status|
                table_array << [item, Project.yesno(status)]
              }
              view_table = TTY::Table.new(["Item", "Done"],table_array)
              puts view_table.render(:unicode, alignments: [:left, :center])
            end
            add_select = @@prompt.select("Add or Select Item", filter: true, per_page: $task_hash[@@task][:checklist].length+2) do |menu|
              menu.choice "Add Item"
              $task_hash[@@task][:checklist].each { |item, status|
              if status != true
                menu.choice "Completed #{item}"
              end
              }
              menu.choice "Back to Edit"
            end
            if add_select == "Add Item"
              list_item = @@prompt.ask("Input checklist item", validate: /^[\w\-\s]+$/)
              $task_hash[@@task][:checklist][list_item] = false
            elsif add_select == "Back to Edit"
              back_to_edit = true
            else
              $task_hash[@@task][:checklist].each { |item, status|
              if status != true
                case add_select 
                when "Completed #{item}"
                  $task_hash[@@task][:checklist]["#{item}"] = true
                end
              end
            }
            end
          end
        elsif status == "Add Comment"
          if $task_hash[@@task][:comments] == false
            comments = Hash.new
            $task_hash[@@task][:comments] = comments
          end
          comment = @@prompt.multiline("Input Task comment")
          $task_hash[@@task][:comments][Time.new] = comment
        elsif status == "Add Tags"
          tags = @@prompt.multiline("Input tags separated by a new line (enter/return)")
          $task_hash[@@task][:tags] += tags
        else
          @@back_to_main = true
        end
      end

    end

    # Selects and deletes a task
    def Project.delete_task
      Project.select_task
      yn = @@prompt.yes?("Are you sure you wish to delete '#{@@task}'? (non reversable)")
      if yn == true
      $task_hash.delete(@@task.to_s)
      end
    end

    def Project.pdf
      puts "Functionality not built yet - watch this space!"
    end

    # Converts boolean into a check or cross
    def Project.yesno(boolean)
      checkmark = "\u2713"
      crossmark = "\u2717"

      boolean ? checkmark.encode('utf-8') : crossmark.encode('utf-8')
    end
    

end