class Wikis::SectionsController < Wikis::BaseController

  stylesheet 'wiki_edit'
  javascript :wiki, :action => :edit

  #before_filter :ensure_desired_locked_section_exists, :only => [:edit, :update]
  # if we have some section locked, but we don't need it. we should drop the lock
  #before_filter :release_old_locked_section!, :only => [:edit, :update]

  def edit
    @section = params[:id]
    @markup = @wiki.get_body_for_section(@section)
    if params[:break_lock]
      # remove other peoples lock if it exists
      @wiki.unlock!(@section, current_user, :break => true )
    end
    if @wiki.section_open_for?(@section, current_user)
      @wiki.lock!(@section, current_user)
    else
      render :template => '/wikis/sections/locked'
    end
  end

# TODO: versioning for sections
  def update
    @section = params[:id]
    if params[:cancel]
      @wiki.unlock!(@section, current_user, :break => true ) if @wiki
    else
      @wiki.update_section!(@section, current_user, nil, params[:wiki][:body])
      success
    end
    redirect_to @page ? page_url(@page) : group_wiki_path(@group, @wiki)

  rescue Wiki::VersionExistsError, Wiki::SectionLockedOnSaveError => exc
    warning exc
    @wiki.body = params[:wiki][:body]
    # @wiki.version = @wiki.versions.last.version + 1
    # this won't unlock if they don't hit save:
    @wiki.unlock!(:document, current_user, :break => true )
    render :template => '/wikis/sections/edit'
  end


protected

  ### FILTERS
#  def prepare_wiki_body_html
#    if current_locked_section and current_locked_section != :document
#      @wiki.body_html = body_html_with_form(current_locked_section)
#    end
#  end


end
