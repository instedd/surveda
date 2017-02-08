declare module 'react-redux' {
  //   declare function connect<P, S, IP, C, Def, SS>(m: (S) => IP):
  //     (c: Class<React$Component<Def, P, SS>>) =>
  //       Class<React$Component<Def, $Diff<$Diff<P, IP>, { dispatch: Function }>, SS>>;

  //   declare function connect<P, S, IP, D, D2, IP2, C, Def, SS>(m: (S) => IP, q: (D, D2) => IP2):
  //     (c: Class<React$Component<Def, P, SS>>) =>
  //       Class<React$Component<Def, $Diff<$Diff<P, IP & IP2>, { dispatch: Function }>, SS>>;

  //   declare function connect<P, D, IP2, C, Def, SS>(m: null, q: (D) => IP2):
  //     (c: Class<React$Component<Def, P, SS>>) =>
  //       Class<React$Component<Def, $Diff<$Diff<P, IP2>, { dispatch: Function }>, SS>>;

  declare type MapStateToProps<OP, SP> = (state: any, ownProps: OP) => SP;
  declare type MapDispatchToProps<OP, DP> = (dispatch: Function, ownProps: OP) => DP;

  declare type Connect<P, SP, DP> = <Def, S>(c: Class<React$Component<Def, P, S>>) => Class<React$Component<Def, $Diff<$Diff<P, SP>, DP>, S>>;

  declare function connect<P, OP, SP, DP>(
    mapStateToProps: MapStateToProps<OP, SP>,
    mapDispatchToProps: MapDispatchToProps<OP, DP>
  ): Connect<P, SP, DP>

  declare function connect<P, OP, SP>(
    mapStateToProps: MapStateToProps<OP, SP>,
    mapDispatchToProps: null | void
  ): Connect<P, SP, {dispatch: Function}>

  declare function connect<P, OP, DP>(
    mapStateToProps: null,
    mapDispatchToProps: MapDispatchToProps<OP, DP>
  ): Connect<P, void, DP>
}
