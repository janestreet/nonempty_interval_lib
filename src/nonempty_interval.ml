open! Core
open! Interval_lib
include Nonempty_interval_intf

module%template.portable
  [@mode m = (global, local)] [@modality p]
  Make
    (Bound : Bound
  [@mode m]) =
struct
  include Interval.Make [@mode m] [@modality p] (Bound)

  let of_interval interval = Option.some_if (not (is_empty interval)) interval

  let of_interval_exn interval =
    match of_interval interval with
    | Some interval -> interval
    | None -> invalid_arg "[of_interval_exn] called on empty interval"
  ;;

  let to_interval t = t
  let singleton bound = create bound bound

  let create lbound ubound =
    let interval = create lbound ubound in
    of_interval interval
  ;;

  let create_exn lbound ubound =
    match create lbound ubound with
    | Some interval -> interval
    | None ->
      invalid_arg
        (Sexp.to_string_hum
           [%message
             "Lower bound strictly greater than upper bound:"
               (lbound : Bound.t)
               (ubound : Bound.t)])
  ;;

  let intersect t t' =
    let intersection = intersect t t' in
    of_interval intersection
  ;;

  (* [is_singleton] takes a [t], which cannot be instantiated if empty. Therefore, if
     [is_empty_or_singleton t] is true, [t] must be a singleton. *)
  let is_singleton = is_empty_or_singleton
  let bounds = bounds_exn
  let lbound = lbound_exn
  let ubound = ubound_exn
  let convex_hull ts = Nonempty_list.to_list ts |> convex_hull

  let compare_value t bound =
    match compare_value t bound with
    | (`Below | `Within | `Above) as compared -> compared
    | `Interval_is_empty ->
      raise_s
        [%message "[Nonempty_interval.t]s are not expected to be empty. Is this a bug?"]
  ;;

  let bound t x = bound t x |> Option.value_exn

  let map t ~f =
    let interval = map t ~f in
    of_interval interval
  ;;

  let map_exn t ~f =
    match map t ~f with
    | Some interval -> interval
    | None ->
      raise_s
        [%message
          "Mapping a [Nonempty_interval.t] to an empty interval is disallowed:" (t : t)]
  ;;
end

module%template [@mode m = (global, local)] Make_stable (Bound : Bound_stable [@mode m]) =
struct
  include Make [@mode m] (Bound)

  module Stable = struct
    module V1 = struct
      type t = Bound.t Interval.Stable.V1.t
      [@@deriving
        bin_io
        , (compare [@mode.explicit m])
        , (equal [@mode.explicit m])
        , hash
        , sexp
        , stable_witness]
    end
  end
end

module%template
  [@mode m = (global, local)]
  Make_stable_with_sexp_grammar
    (Bound : Bound_stable_with_sexp_grammar
  [@mode m]) =
struct
  include Make [@mode m] (Bound)

  module Stable = struct
    module V1 = struct
      type t = Bound.t Interval.Stable.V1.t
      [@@deriving
        bin_io
        , (compare [@mode.explicit m])
        , (equal [@mode.explicit m])
        , hash
        , sexp
        , stable_witness
        , sexp_grammar]
    end
  end
end

module%template Date = Make_stable [@mode local] (struct
    include Date.Stable.V1
    include Comparable.Make [@mode local] (Date.Stable.V1)
  end)

module%template Float = Make_stable [@mode local] (struct
    include Float.Stable.V1
    include Comparable.Make [@mode local] (Float.Stable.V1)
  end)

module%template Ofday_ns = Make_stable [@mode local] (struct
    include Time_ns.Stable.Ofday.V1
    include Comparable.Make [@mode local] (Time_ns.Stable.Ofday.V1)
  end)

module%template Span_ns = Make_stable [@mode local] (struct
    include Time_ns.Stable.Span.V2
    include Comparable.Make [@mode local] (Time_ns.Stable.Span.V2)
  end)
