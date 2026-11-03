open! Core

(** See {!Nonempty_interval} below. *)

module type%template [@mode m = (global, local)] S = sig
  type bound

  type t : value mod contended portable with bound
  [@@deriving
    (bin_io [@mode m])
    , sexp
    , (compare [@mode.explicit m])
    , (equal [@mode.explicit m])
    , hash]

  type interval

  (** [Set] is a set of pairwise-disjoint nonempty intervals. *)
  module Set : sig
    type outer := t
    type t [@@deriving bin_io, sexp]

    (** [create_from_intervals_exn outers] raises if [outers] are not disjoint. *)
    val create_from_intervals_exn : outer list -> t

    val union_list : t list -> t

    (** [to_list] returns intervals in ascending order. *)
    val to_list : t -> outer list
  end

  val of_interval : interval -> t option
  val of_interval_exn : interval -> t
  val to_interval : t -> interval

  (** [create l u] returns [Some] interval with lower bound [l] and upper bound [u],
      unless [l > u], in which case it returns [None]. *)
  val create : bound -> bound -> t option

  (** [create_exn] is the same as {!val:create} except it raises on [None]. *)
  val create_exn : bound -> bound -> t

  (** [singleton] returns an interval with the lower bound equal to the upper bound. *)
  val singleton : bound -> t

  val intersect : t -> t -> t option
  val is_singleton : t -> bool
  val bounds : t -> bound * bound
  val lbound : t -> bound
  val ubound : t -> bound
  val convex_hull : t Nonempty_list.t -> t
  val contains : t -> bound -> bool
  val compare_value : t -> bound -> [ `Below | `Within | `Above ]
  val bound : t -> bound -> bound
  val is_superset : t -> of_:t -> bool
  val is_subset : t -> of_:t -> bool

  (** [map t ~f] returns [Some (create (f l) (f u))] if the resulting interval is
      nonempty, else it returns [None]. *)
  val map : t -> f:(bound -> bound) -> t option

  (** [map_exn] is the same as {!val:map} except it raises on [None]. *)
  val map_exn : t -> f:(bound -> bound) -> t

  val are_disjoint : t list -> bool
  val are_disjoint_as_open_intervals : t list -> bool
  val list_intersect : t list -> t list -> t list
  val half_open_intervals_are_a_partition : t list -> bool
end

module type%template [@mode m = (global, local)] S_stable = sig
  include S [@mode m]

  module Stable : sig
    module V1 : sig
      type nonrec t = t
      [@@deriving
        bin_io
        , (compare [@mode.explicit m])
        , (equal [@mode.explicit m])
        , sexp
        , stable_witness
        , hash]
    end
  end
end

module type%template [@mode m = (global, local)] S_stable_with_sexp_grammar = sig
  include S_stable [@mode m]

  module Stable : sig
    include module type of Stable

    module V1 : sig
      type nonrec t = t [@@deriving sexp_grammar]

      include module type of V1 with type t := t
    end
  end
end

module type%template [@mode m = (global, local)] Bound = sig
  type t [@@deriving (bin_io [@mode m]), sexp, hash]

  include Comparable.S [@mode m] with type t := t
end

module type%template [@mode m = (global, local)] Bound_stable = sig
  type t [@@deriving stable_witness]

  include Bound [@mode m] with type t := t
end

module type%template [@mode m = (global, local)] Bound_stable_with_sexp_grammar = sig
  type t [@@deriving stable_witness, sexp_grammar]

  include Bound [@mode m] with type t := t
end

module type Nonempty_interval = sig
  (** [Nonempty_interval] is [Interval_lib.Interval] but with empty intervals disallowed.

      This adds a layer of safety if you don't expect your intervals to be empty. And it
      allows for more convenient accessors that return values instead of value options. *)

  [%%template:
  [@@@mode.default m = (global, local)]

  module type Bound = Bound [@mode m]
  module type Bound_stable = Bound_stable [@mode m]
  module type Bound_stable_with_sexp_grammar = Bound_stable_with_sexp_grammar [@mode m]
  module type S = S [@mode m]
  module type S_stable = S_stable [@mode m]
  module type S_stable_with_sexp_grammar = S_stable_with_sexp_grammar [@mode m]]

  module%template.portable [@mode m = (global, local)] Make (Bound : Bound [@mode m]) :
    S
    [@mode m]
    with type bound = Bound.t
     and type interval := Interval_lib.Interval.Make(Bound).t

  module%template
    [@mode m = (global, local)]
    Make_stable
      (Bound : Bound_stable
    [@mode m]) :
    S_stable
    [@mode m]
    with type bound = Bound.t
     and type interval := Interval_lib.Interval.Make(Bound).t

  module%template
    [@mode m = (global, local)]
    Make_stable_with_sexp_grammar
      (Bound : Bound_stable_with_sexp_grammar
    [@mode m]) :
    S_stable_with_sexp_grammar
    [@mode m]
    with type bound = Bound.t
     and type interval := Interval_lib.Interval.Make(Bound).t

  module%template Date :
    S_stable
    [@mode local]
    with type bound = Date.t
     and type interval := Interval_lib.Interval.Make(Date).t

  module%template Float :
    S_stable
    [@mode local]
    with type bound = float
     and type interval := Interval_lib.Interval.Float.t

  module%template Ofday_ns :
    S_stable
    [@mode local]
    with type bound = Time_ns.Ofday.t
     and type interval := Interval_lib.Interval.Ofday_ns.t

  module%template Span_ns :
    S_stable
    [@mode local]
    with type bound = Time_ns.Span.t
     and type interval := Interval_lib.Interval.Make(Time_ns.Span).t
end
