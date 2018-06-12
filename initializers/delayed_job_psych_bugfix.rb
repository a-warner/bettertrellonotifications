delayed_job_version = Gem.loaded_specs['delayed_job'].version.to_s

unless '4.0.0' == delayed_job_version
  raise LoadError, "Delayed Job has been upgraded to #{delayed_job_version}, consider deleting this monkeypatch"
end

module Psych
  module Visitors
    class ToRuby
      def visit_Psych_Nodes_Mapping_with_delayed_jobs_bugfix(object)
        return revive(Psych.load_tags[object.tag].constantize, object) if Psych.load_tags[object.tag]

        visit_Psych_Nodes_Mapping_without_delayed_jobs_bugfix(object)
      end
      alias_method_chain :visit_Psych_Nodes_Mapping, :delayed_jobs_bugfix
    end
  end
end
