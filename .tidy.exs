%{
  checks: [
    {Tidy.Checks.DescribeOptions, [level: :warning, args: [:opts, :options]]},
    # {Tidy.Checks.FunctionArgumentDocumentation,
    #  [level: :warning, exceptions: ["opts", "options"]]},
    {Tidy.Checks.FunctionDoc, [level: :error]},
    {Tidy.Checks.FunctionExamples, [level: :suggest]},
    {Tidy.Checks.FunctionSpec, [level: :error]},
    {Tidy.Checks.ImplementationMentionBehavior, [level: :warning, args: [:opts, :options]]},
    {Tidy.Checks.ModuleDoc, [level: :error]}
  ],
  ignore: %{
    functions: [
      __changeset__: 0,
      __intercepts__: 0,
      __phoenix_recompile__?: 0,
      __protocol__: 1,
      __resource__: 0,
      __schema__: 1,
      __schema__: 2,
      __socket__: 1,
      __struct__: 0,
      __struct__: 1,
      __templates__: 0
    ],
    modules: []
  }
}
