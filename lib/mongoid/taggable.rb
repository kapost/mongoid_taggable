# Copyright (c) 2010 Wilker Lúcio <wilkerlucio@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongoid::Taggable
  def self.included(base)
    # create fields for tags and index it
    base.field :tags_array, :type => Array, :default => []
    base.index 'tags_array' => 1


    # extend model
    base.extend         ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
    # returns an array of distinct ordered list of tags defined in all documents

    def tagged_with(tag)
      self.any_in(:tags_array => [tag])
    end

    def tagged_with_all(*tags)
      self.all_in(:tags_array => tags.flatten)
    end
    
    def tagged_with_any(*tags)
      self.any_in(:tags_array => tags.flatten)
    end

    def tags_separator(separator = nil)
      @tags_separator = separator if separator
      @tags_separator || ','
    end
  end

  module InstanceMethods
    def tags
      (tags_array || []).join(self.class.tags_separator)
    end

    def tags=(tags)
      self.tags_array = tags.split(self.class.tags_separator).map(&:strip).reject(&:blank?)
    end
  end
end
