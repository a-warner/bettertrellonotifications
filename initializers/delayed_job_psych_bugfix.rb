delayed_job_version = Gem.loaded_specs['delayed_job'].version.to_s

unless '4.0.6' == delayed_job_version
  raise LoadError, "Delayed Job has been upgraded to #{delayed_job_version}, consider deleting this monkeypatch"
end

module FixPsych
  def visit_Psych_Nodes_Mapping(object)
    return revive(Psych.load_tags[object.tag].constantize, object) if Psych.load_tags[object.tag]

    super(object)
  end
end

Psych::Visitors::ToRuby.prepend(FixPsych)
Delayed::PsychExt::ToRuby.prepend(FixPsych)
