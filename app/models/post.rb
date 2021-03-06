class Post < ActiveRecord::Base
  belongs_to :pitch
  belongs_to :user
  
  after_save :touch_pitch
  
  has_attached_file :blog_image,
                      :styles => { :thumb => '50x50#', 
                          :medium => "200x150#", 
                          :front_story => "300x163#", 
                          :medium_alt=>"215x180#", 
                          :medium_alt_1=>"268x210#" },
                      :storage => :s3,
                      :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
                      :bucket =>   S3_BUCKET,
                      :path => "posts/" <<
                               ":attachment/:id_partition/" <<
                               ":basename_:style.:extension",
                      :url =>  "posts/:attachment/:id_partition/" <<
                               ":basename_:style.:extension",
                      :default_url => "/images/featured_images/missing_:style.png"
                      
  if Rails.env.production?
    validates_attachment_content_type :blog_image,
      :content_type => ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png',
                        'image/x-png', 'image/jpg'],
      :message      => "Oops! Make sure you are uploading an image file."

    validates_attachment_size :blog_image, :in => 1..5.megabytes
  end
  validates_presence_of :title, :body, :user, :pitch
  
  def blog_posted_notification
    Mailer.deliver_blog_posted_notification(self)
  end
  
  def blog_image_display(style)
    return blog_image.url(style) if blog_image_file_name
    return pitch.featured_image.url(style)
  end
  
  named_scope :by_network, lambda {|network|
    return {} unless network
    {:conditions =>  ["pitch_id in (select id from news_items where network_id in (select id from networks where id = ?))", network]}
    }
    named_scope :latest, :order => "posts.id desc", :limit => 3
    
  def touch_pitch
    self.pitch.touch_pitch!
  end

end
