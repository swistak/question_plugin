class QuestionIssueHooks < QuestionHooksBase
  # Applies the question class to each journal div if they are questions
  def view_issues_history_journal_bottom(context = { })
    o = ''
    if context[:journal] && context[:journal].question && context[:journal].question.opened?
      question = context[:journal].question
      
      if question.assigned_to
        html = assigned_question_html(question)
      else
        html = unassigned_question_html(question)
      end

      o += <<JS
<script type='text/javascript'>
   $('change-#{context[:journal].id}').addClassName('question');
   $$('#change-#{context[:journal].id} h4 div').each(function(ele) { ele.insert({ top: ' #{html} ' }) });
</script>
JS
      
    end
    return o
  end
  
  def view_issues_edit_notes_bottom(context = { })
    f = context[:form]
    @issue = context[:issue]
    o = ''
    o << content_tag(:p, 
                     "<label>#{l(:field_question_assign_to)}</label> " + 
                     select(:note,
                            :question_assigned_to,
                            [[l(:text_anyone), :anyone]] + (@issue.assignable_users.collect {|m| [m.name, m.id]}),
                            :include_blank => true))
    return o
  end
  
  def controller_issues_edit_before_save(context = { })
    params = context[:params]
    journal = context[:journal]
    issue = context[:issue]
    if params[:note] && !params[:note][:question_assigned_to].blank?
      unless journal.question # Update handled by Journal hooks
        # New
        journal.question = Question.new(
                                        :author => User.current,
                                        :issue => journal.issue
                                        )
        if params[:note][:question_assigned_to] != 'anyone'
          # Assigned to a specific user
          assign_question_to_user(journal, User.find(params[:note][:question_assigned_to].to_i))
        end
      end
    end
    
    return ''
  end
  
  def view_issues_sidebar_issues_bottom(context = { })
    project = context[:project]
    if project
      query_string = "SELECT COUNT(questions.id) FROM questions, issues WHERE #{Question.table_name}.issue_id = #{Issue.table_name}.id"
      query_string << " AND #{Question.table_name}.assigned_to_id = ?"
      query_string << " AND #{Issue.table_name}.project_id = ?"
      query_string << " AND #{Question.table_name}.opened = ?"
      question_count = Question.count_by_sql([query_string, User.current, project.id, true])
    else
      question_count = Question.count(:conditions => {:assigned_to_id => User.current, :opened => true})
    end
    
    if question_count > 0
      return link_to(l(:text_questions_for_me) + " (#{question_count})",
                     {
                       :controller => 'questions',
                       :action => 'my_issue_filter',
                       :project => project,
                       :only_path => true
                     },
                     { :class => 'question-link' }
                     )
    else
      return ''
    end
    
  end

  private
  
  def assign_question_to_user(journal, user)
    journal.question.assigned_to = user
  end
end
