class ExpendituresController < ApplicationController
  unloadable

  menu_item :metrics
  before_filter :find_project_by_project_id, :authorize
  before_filter :find_expenditure, :only => [:show, :edit, :update, :destroy]

  helper :cmi

  def index
    @limit = per_page_option
    @count = CmiExpenditure.count
    @pages = Paginator.new self, @count, @limit, params['page']
    @offset ||= @pages.current.offset
    @sort = sort_column
    @order = sort_direction
    @expenditures = CmiExpenditure.all(:conditions => ['project_id = ?', @project],
                                       :order => [@sort, @order].join(' '),
                                       :offset => @offset,
                                       :limit => @limit)
  end

  def new
    @expenditure = CmiExpenditure.new
  end

  def create
    @expenditure = CmiExpenditure.new params[:expenditure]
    @expenditure.project = @project
    @expenditure.author = User.current
    if @expenditure.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => :index
    else
      # get_roles
      render :action => 'new'
    end
  end

  def show
    @journals = @expenditure.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
  end

  def edit
    @journal = @expenditure.current_journal
  end

  def update
    @expenditure.init_journal(User.current, params[:notes])
    @expenditure.attributes = params[:expenditure]
    if @expenditure.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({:action => 'show', :id => @expenditure})
    else
      # get_roles
      @journal = @expenditure.current_journal
      render :action => 'edit'
    end
  end

  def destroy
    @expenditure.destroy
    redirect_back_or_default(:action => 'index', :project_id => @project)
  end

  private

  def find_expenditure
    @expenditure = CmiExpenditure.find params[:id]
    unless @expenditure.project_id == @project.id
      deny_access
      return
    end
  end

  def sort_column
    CmiExpenditure.column_names.include?(params[:sort]) ? params[:sort] : "concept"
  end

  def sort_direction
    %w[asc desc].include?(params[:order]) ? params[:order] : "asc"
  end

  # def get_roles
  #   @roles = User.roles
  # end
end