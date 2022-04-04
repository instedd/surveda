declare module "react-redux" {
  declare type MapStateToProps<OP, SP> = (state: any, ownProps: OP) => SP
  declare type MapDispatchToProps<OP, DP> = (dispatch: Function, ownProps: OP) => DP

  declare type Connect<P, SP, DP> = <S>(
    c: Class<React$Component<P, S>>
  ) => Class<React$Component<$Diff<$Diff<P, SP>, DP>, S>>

  declare function connect<P, OP, SP, DP>(
    mapStateToProps: MapStateToProps<OP, SP>,
    mapDispatchToProps: MapDispatchToProps<OP, DP>
  ): Connect<P, SP, DP>

  declare function connect<P, OP, SP>(
    mapStateToProps: MapStateToProps<OP, SP>,
    mapDispatchToProps: null | void
  ): Connect<P, SP, void>

  declare function connect<P, OP, DP>(
    mapStateToProps: null,
    mapDispatchToProps: MapDispatchToProps<OP, DP>
  ): Connect<P, void, DP>

  declare function connect<P, OP, DP>(
    mapStateToProps: null | void,
    mapDispatchToProps: null | void
  ): Connect<P, void, void>
}
