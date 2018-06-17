Require Import List.
Require Import BinPos.
Require Import Bool.
Require Import Coq.Arith.PeanoNat.
Require Import Sumbool.


(* Some helpful lemmas regarding List *)

(* If List.length l = 1, l = h::nil. *)
Lemma list_len1:
  forall {X:Type} (l:list X)
         (H:List.length l = 1),
    exists h, l = h::nil.
Proof.
  intros.
  destruct l.
  - simpl in H. inversion H.
  - destruct l.
    + eexists. reflexivity.
    + simpl in H. inversion H.
Qed.

(* If List.length l = 2, l = h1::h2::nil. *)
Lemma list_len2:
  forall {X:Type} (l:list X)
         (H:List.length l = 2),
    exists h1 h2, l = h1::h2::nil.
Proof.
  intros.
  destruct l.
  - simpl in H. inversion H.
  - destruct l.
    + simpl in H. inversion H.
    + destruct l.
      * eexists. eexists. reflexivity.
      * simpl in H. inversion H.
Qed.

Lemma filter_length:
  forall {X:Type} (l:list X) f,
    List.length (List.filter f l) <= List.length l.
Proof.
  intros.
  induction l.
  - simpl. auto.
  - simpl.
    destruct (f a).
    + simpl.
      apply Le.le_n_S.
      assumption.
    + apply le_S.
      assumption.
Qed.

(* the result of List.filter satisfies forallb. *)
Lemma filter_forallb: forall {X:Type} (l:list X) f,
    List.forallb f (List.filter f l) = true.
Proof.
  intros.
  induction l. reflexivity. simpl.
  destruct (f a) eqn:H. simpl. rewrite H. rewrite IHl. auto.
  assumption.
Qed.

(* Why do I need this? *)
Lemma list_eq:
  forall {X:Type} (a b:X) (c d:list X)
    (HEQ:a = b)
    (HEQ2:c = d),
    a::c = b::d.
Proof.
  intros.
  rewrite HEQ.
  rewrite HEQ2.
  reflexivity.
Qed.

(* If map f b = a,
   and p = split (filter g (combine a b)),
   map f p.snd = p.fst. *)
Lemma split_filter_combine_map:
  forall {X Y:Type} (a:list X) (b:list Y) p f g
         (HMAP:List.map f b = a)
         (HP:p = List.split (List.filter g (List.combine a b))),
    List.map f p.(snd) = p.(fst).
Proof.
  intros.
  remember (combine a b) as ab.
  generalize dependent a.
  generalize dependent b.
  generalize dependent p.
  induction ab as [| abh abt].
  - intros. simpl in HP. rewrite HP. reflexivity.
  - intros.
    destruct (split (filter g abt)) as [abtl abtr] eqn:HS.
    simpl in HP.
    destruct a as [| ah at'].
    { simpl in Heqab. inversion Heqab. }
    destruct b as [| bh bt].
    { simpl in Heqab. inversion Heqab. }
    destruct (g abh).
    + destruct abh as [abhl abhr].
      simpl in Heqab.
      inversion Heqab.
      rewrite H0 in *. clear H0.
      rewrite H1 in *. clear H1. clear Heqab.
      simpl in HP.
      rewrite HS in HP.
      rewrite HP.
      simpl.
      simpl in HMAP.
      inversion HMAP.
      rewrite H0 in *. clear H0.
      rewrite H1 in *. clear HMAP.
      apply list_eq. reflexivity.
      assert (abtr = snd (split (filter g abt))).
      { rewrite HS. reflexivity. }
      assert (abtl = fst (split (filter g abt))).
      { rewrite HS. reflexivity. }
      rewrite H. rewrite H0.
      eapply IHabt.
      * assumption.
      * apply H1.
      * assumption.
    + apply IHabt with (b := bt) (a := at').
      * rewrite HP. assumption.
      * simpl in HMAP.
        inversion HMAP. reflexivity.
      * simpl in Heqab.
        inversion Heqab.
        reflexivity.
Qed.

Lemma In_map:
  forall {X Y:Type} (l:list X) (f:X -> Y) (y:Y)
         (HIN:List.In y (List.map f l)),
    exists (x:X), f x = y /\ List.In x l.
Proof.
  induction l.
  intros. simpl in HIN. inversion HIN.
  intros.
  simpl in HIN.
  destruct HIN.
  - eexists. split. eassumption. constructor. reflexivity.
  - apply IHl in H.
    destruct H as [xH H].
    destruct H as [H1 H2].
    eexists.
    split. eassumption. simpl. right. assumption.
Qed.


(* Function version of List.incl *)

Definition list_incl {X:Type}
           {eq_dec: forall x y : X, {x = y}+{x <> y}}
           (l1 l2: list X): bool :=
  List.forallb (fun x =>
                  List.existsb (fun y =>
                     match (eq_dec x y) with
                     | left _ => true
                     | right _ => false
                     end) l2) l1.


(*******************************************
      Subsequence of a list.
 *******************************************)

Inductive lsubseq {X:Type}: list X -> list X -> Prop :=
| ss_nil: forall (l:list X), lsubseq l nil
| ss_cons: forall (x:X) (l1 l2:list X) (H:lsubseq l1 l2),
    lsubseq (x::l1) (x::l2)
| ss_elon: forall (x:X) (l1 l2:list X) (H:lsubseq l1 l2),
    lsubseq (x::l1) l2.

Lemma lsubseq_refl: forall {X:Type} (l:list X), lsubseq l l.
Proof.
  intros.
  induction l. constructor. constructor. assumption.
Qed.

Lemma lsubseq_inv:
  forall {X:Type} (l1 l2:list X) (x:X)
         (H:lsubseq l1 (x::l2)),
    lsubseq l1 l2.
Proof.
  intros.
  induction l1.
  - inversion H.
  - inversion H.
    + apply ss_elon. assumption.
    + apply ss_elon. apply IHl1.
      assumption.
Qed.

Lemma lsubseq_trans:
  forall {X:Type} (l1 l2 l3:list X)
         (H1:lsubseq l1 l2)
         (H2:lsubseq l2 l3),
    lsubseq l1 l3.
Proof.
  intros.
  generalize dependent l3.
  induction H1 as [| x l1' l2' | x l1' l2'].
  - intros. inversion H2. constructor.
  - intros.
    inversion H2 as [| y l2'' l3' | y l2'' l3'].
    + constructor.
    + constructor. apply IHlsubseq. assumption.
    + apply ss_elon.
      apply IHlsubseq.
      assumption.
  - intros.
    apply ss_elon.
    apply IHlsubseq.
    assumption.
Qed.    

Lemma lsubseq_In:
  forall {X:Type} (l l':list X) (x:X)
         (HIN:List.In x l')
         (HLSS:lsubseq l l'),
    List.In x l.
Proof.
  intros.
  induction HLSS.
  - simpl in HIN. inversion HIN.
  - simpl in HIN.
    destruct HIN.
    + rewrite H. simpl. auto.
    + simpl. right. apply IHHLSS. assumption.
  - simpl. right. apply IHHLSS. assumption.
Qed.

Lemma lsubseq_filter: forall {X:Type} (l:list X) f,
    lsubseq l (List.filter f l).
Proof.
  intros.
  induction l. constructor. simpl.
  destruct (f a) eqn:H. constructor. assumption.
  constructor. assumption.
Qed.

Lemma lsubseq_append: forall {X:Type} (l1 l2 l3 l4:list X)
                             (H1:lsubseq l1 l2)
                             (H2:lsubseq l3 l4),
    lsubseq (l1++l3) (l2++l4).
Proof.
  intros.
  induction H1.
  - simpl.
    induction l. assumption.
    simpl. constructor. assumption.
  - simpl. constructor. assumption.
  - simpl. constructor. assumption.
Qed.

Lemma lsubseq_forallb: forall {X:Type} (l l':list X) f
                             (H:List.forallb f l = true)
                             (HLSS:lsubseq l l'),
    List.forallb f l' = true.
Proof.
  intros.
  induction HLSS.
  - constructor.
  - simpl in *.
    rewrite andb_true_iff in *.
    destruct H.
    split. assumption. apply IHHLSS. assumption.
  - simpl in H. rewrite andb_true_iff in H.
    destruct H. apply IHHLSS. assumption.
Qed.


(*******************************************
      Definition of range & disjointness.
 *******************************************)

Definition disjoint_range (r1 r2:nat * nat): bool :=
  match (r1, r2) with
  | ((b1, len1), (b2, len2)) =>
    Nat.leb (b1 + len1) b2 || Nat.leb (b2 + len2) b1
  end.

Fixpoint disjoint_ranges (rs:list (nat*nat)): bool :=
  match rs with
  | nil => true
  | r::t => List.forallb (fun r2 => disjoint_range r r2) t && disjoint_ranges t
  end.

Definition in_range (i:nat) (r:nat * nat): bool :=
  Nat.leb r.(fst) i && Nat.leb i (r.(fst) + r.(snd)).

(* Returns a list of ranges which include i. *)
Definition disjoint_include (rs:list (nat * nat)) (i:nat): list (nat*nat) :=
  List.filter (in_range i) rs.

Definition disjoint_include2 {X:Type} (rs:list (nat * nat)) (data:list X) (i:nat)
: list (nat*nat) * list X :=
  List.split
    (List.filter (fun x => in_range i x.(fst))
                 (List.combine rs data)).

Definition no_empty_range (rs:list (nat * nat)): bool :=
  List.forallb (fun t => Nat.ltb 0 t.(snd)) rs.



(* Lemma: two ranges with same begin index & non-zero length overlaps. *)
Lemma disjoint_same:
  forall b1 b2 l1 l2 (HL1:0 < l1) (HL2: 0 < l2) (HEQ:b1 = b2),
    disjoint_range (b1, l1) (b2, l2) = false.
Proof.
  intros.
  unfold disjoint_range.
  rewrite orb_false_iff.
  repeat (rewrite Nat.leb_nle).
  split; rewrite HEQ; apply Gt.gt_not_le; apply Nat.lt_add_pos_r; auto.
Qed.

(* Same as disjoint_same, but with same end index. *)
Lemma disjoint_same2:
  forall b1 b2 l1 l2 (HL1:0 < l1) (HL2:0 < l2) (HEQ:b1 + l1 = b2 + l2),
    disjoint_range (b1, l1) (b2, l2) = false.
Proof.
  intros.
  unfold disjoint_range.
  rewrite orb_false_iff.
  repeat (rewrite Nat.leb_nle).
  split.
  - rewrite HEQ; apply Gt.gt_not_le; apply Nat.lt_add_pos_r; auto.
  - rewrite <- HEQ; apply Gt.gt_not_le; apply Nat.lt_add_pos_r; auto.
Qed.

(* Lemma: no_empty_range still holds for appended lists *)
Lemma no_empty_range_append:
  forall l1 l2 (H1:no_empty_range l1 = true) (H2:no_empty_range l2 = true),
    no_empty_range (l1++l2) = true.
Proof.
  intros.
  induction l1.
  - simpl. assumption.
  - simpl in H1.
    simpl. rewrite andb_true_iff in *.
    destruct H1.
    split. assumption. apply IHl1. assumption.
Qed.

(* Lemma: no_empty_range holds for subsequences *)
Lemma no_empty_range_lsubseq:
  forall l1 l2 (H1:no_empty_range l1 = true) (HLSS:lsubseq l1 l2),
    no_empty_range l2 = true.
Proof.
  intros.
  induction HLSS. reflexivity.
  simpl. simpl in H1. rewrite andb_true_iff in *.
  destruct H1. split. assumption. apply IHHLSS. assumption.
  apply IHHLSS. simpl in H1. rewrite andb_true_iff in *.
  destruct H1. assumption.
Qed.

(* Lemma: no_empty_range holds for concatenated lists *)
Lemma no_empty_range_concat:
  forall (ll:list (list (nat * nat)))
         (HALL:forall l (HIN:List.In l ll), no_empty_range l = true),
    no_empty_range (List.concat ll) = true.
Proof.
  intros.
  induction ll.
  - reflexivity.
  - simpl. apply no_empty_range_append.
    apply HALL. constructor. reflexivity.
    apply IHll. intros. apply HALL.
    simpl. right. assumption.
Qed.

(* Lemma: the subsequence of disjoint ranges is also disjoint. *)
Lemma disjoint_lsubseq_disjoint:
  forall rs rs'
         (HDISJ:disjoint_ranges rs = true)
         (HLSS:lsubseq rs rs'),
    disjoint_ranges rs' = true.
Proof.
  intros.
  induction HLSS.
  - constructor.
  - simpl in *.
    rewrite andb_true_iff in *.
    destruct HDISJ as [HDISJ1 HDISJ2].
    split.
    + apply lsubseq_forallb with (l := l1).
      assumption.
      assumption.
    + apply IHHLSS. assumption.
  - simpl in HDISJ.
    rewrite andb_true_iff in HDISJ.
    destruct HDISJ as [_ HDISJ].
    apply IHHLSS. assumption.
Qed.

Lemma disjoint_ranges_append:
  forall l1 l2 (HDISJ:disjoint_ranges (l1 ++ l2) = true),
    disjoint_ranges l1 = true /\ disjoint_ranges l2 = true.
Proof.
  intros.
  induction l1.
  - simpl in HDISJ.
    split. reflexivity. assumption.
  - simpl in HDISJ.
    rewrite andb_true_iff in HDISJ.
    destruct HDISJ.
    split. simpl. rewrite andb_true_iff. split.
    rewrite forallb_app in H.
    rewrite andb_true_iff in H.
    destruct H. assumption.
    apply IHl1. assumption.
    apply IHl1. assumption.
Qed.

(* Lemma: the result of disjoint_include is subsequence of the input. *)
Lemma disjoint_include_lsubseq:
  forall rs i, lsubseq rs (disjoint_include rs i).
Proof.
  intros. unfold disjoint_include. apply lsubseq_filter.
Qed.

(* Lemma: (disjoint_include2 rs data i).fst = disjoint_include rs i *)
Lemma disjoint_include_include2 {X:Type} :
  forall rs (data:list X) i
    (HLEN:List.length rs = List.length data),
    fst (disjoint_include2 rs data i) = disjoint_include rs i.
Proof.
  intros.
  unfold disjoint_include2.
  unfold disjoint_include.
  generalize dependent data.
  induction rs.
  - intros. simpl in HLEN.
    symmetry in HLEN.
    rewrite length_zero_iff_nil in HLEN.
    rewrite HLEN.
    reflexivity.
  - intros.
    destruct data as [ | dh dt].
    + simpl in HLEN. inversion HLEN.
    + simpl in HLEN. inversion HLEN.
      simpl.
      destruct (in_range i a) eqn:HIN.
      * simpl.
        rewrite <- (IHrs dt).
        destruct (split (filter
                           (fun x : nat * nat * X => in_range i (fst x))
                           (combine rs dt))) eqn:H.
        reflexivity. assumption.
      * rewrite <- (IHrs dt).
        reflexivity. assumption.
Qed.

Lemma disjoint_include2_lsubseq {X:Type}:
  forall (l l': list X) rs rs' ofs
         (HDISJ: disjoint_include2 rs l ofs = (rs', l')),
    lsubseq rs rs' /\ lsubseq l l'.
Proof.
  intros.
  unfold disjoint_include2 in HDISJ.
  remember (combine rs l) as lcomb.
  generalize dependent l.
  generalize dependent l'.
  generalize dependent rs.
  generalize dependent rs'.
  induction lcomb.
  {
    intros.
    simpl in HDISJ.
    inversion HDISJ.
    split. constructor. constructor.
  }
  {
    intros.
    destruct rs as [|rsh rst];
    destruct l as [|lh lt];
    simpl in Heqlcomb;
    try inversion Heqlcomb.
    clear Heqlcomb.
    rewrite H0 in HDISJ.
    simpl in HDISJ.
    destruct (in_range ofs rsh) eqn:HINR.
    - simpl in HDISJ.
      remember (split (filter (fun x : nat * nat * X => in_range ofs (fst x)) lcomb)) as l0.
      destruct l0 as [rs'' l''].
      inversion HDISJ.
      destruct IHlcomb with (rs' := rs'') (rs := rst) (l' := l'') (l := lt).
      + reflexivity.
      + assumption.
      + split.
        * constructor. assumption.
        * constructor. assumption.
    - destruct IHlcomb with (rs := rst) (rs' := rs') (l := lt) (l' := l').
      + assumption.
      + assumption.
      + split. constructor. assumption.
        constructor. assumption.
  }
Qed.

Lemma disjoint_include2_len {X:Type}:
  forall rs (data:list X) i
         (HLEN:List.length rs = List.length data),
    List.length (fst (disjoint_include2 rs data i)) =
    List.length (snd (disjoint_include2 rs data i)).
Proof.
  intros.
  unfold disjoint_include2.
  rewrite split_length_l.
  rewrite split_length_r.
  reflexivity.
Qed.

(* If ranges can be mapped from data,
   the result of disjoint_include2 can be mapped to. *)
Lemma disjoint_include2_rel {X:Type}:
  forall rs (data:list X) i f
         (HMAP:List.map f data = rs),
    List.map f (snd (disjoint_include2 rs data i)) =
    fst (disjoint_include2 rs data i).
Proof.
  intros.
  remember (disjoint_include2 rs data i) as dj eqn:HDJ. 
  simpl.
  unfold disjoint_include2 in HDJ.
  eapply split_filter_combine_map.
  apply HMAP.
  apply HDJ.
Qed.

(* Given (rs, data) = disjoint_include2 .... , 
   length rs = length data. *)
Lemma disjoint_include2_len2 {X:Type}:
  forall rs (data:list X) i,
    List.length (snd (disjoint_include2 rs data i)) <=
    List.length rs.
Proof.
  intros.
  unfold disjoint_include2.
  rewrite split_length_r.
  apply Nat.le_trans with (List.length (combine rs data)).
  - apply filter_length.
  - rewrite combine_length.
    apply Nat.le_min_l.
Qed.
  

(* Lemma: If there are two ranges (b1, l1), (b2, l2),
   and they include some natural number i,
   and they are disjoint,
   either (b1 + l1 = b2 /\ i = b2) or (b2 + l2 = b1 /\ i = b1). *)
Lemma inrange2_disjoint:
  forall (b1 l1 b2 l2 i:nat)
         (H1:in_range i (b1, l1) = true)
         (H2:in_range i (b2, l2) = true)
         (HDISJ:disjoint_ranges ((b1,l1)::(b2,l2)::nil) = true),
    (b1 + l1 = b2 /\ i = b2) \/ (b2 + l2 = b1 /\ i = b1).
Proof.
  intros.
  unfold in_range in *.
  unfold disjoint_ranges in HDISJ.
  simpl in HDISJ.
  repeat (rewrite andb_true_r in HDISJ).
  unfold disjoint_range in HDISJ.
  rewrite andb_true_iff in *.
  rewrite orb_true_iff in *.
  repeat (rewrite Nat.leb_le in *).
  simpl in *.
  destruct HDISJ.
  - (* Make i = b1 + l1, from b1 + l1 <= i <= b1 + l1. *)
    assert (i = b1 + l1).
    { apply Nat.le_antisymm. apply H1.
      apply Nat.le_trans with (m := b2). assumption. apply H2. }
    (* Make i = b2, from b2 <= i <= b2. *)
    assert (i = b2).
    { apply Nat.le_antisymm.
      apply Nat.le_trans with (m := b1 + l1). apply H1. assumption.
      apply H2. }
    left. split; congruence.
  - (* Make i = b2 + l2, from b2 + l2 <= i <= b2 + l2. *)
    assert (i = b2 + l2).
    { apply Nat.le_antisymm. apply H2.
      apply Nat.le_trans with (m := b1). assumption. apply H1. }
    assert (i = b1).
    { apply Nat.le_antisymm.
      apply Nat.le_trans with (m := b2 + l2). apply H2. assumption.
      apply H1. }
    right. split; congruence.
Qed.

(* Lemma: If there are three ranges (b1, l1), (b2, l2), (b3, l3),
   and they all include some natural number i,
   (e.g. b1<=i<=l1, b2<=i<=l2, b3<=i<=l3),
   and l1 != 0 && l2 != 0 && l3 != 0,
   the three ranges cannot be disjoint. *)
Lemma inrange3_never_disjoint:
  forall (r1 r2 r3:nat * nat) i
         (H1:in_range i r1 = true)
         (H2:in_range i r2 = true)
         (H3:in_range i r3 = true)
         (HNOEMPTY:no_empty_range (r1::r2::r3::nil) = true),
    disjoint_ranges (r1::r2::r3::nil) = false.
Proof.
  intros.
  destruct r1 as [b1 l1].
  destruct r2 as [b2 l2].
  destruct r3 as [b3 l3].
  (* Prettify HNOEMPTY. *)
  simpl in HNOEMPTY.
  rewrite andb_true_r in HNOEMPTY.
  repeat (rewrite andb_true_iff in HNOEMPTY).
  destruct HNOEMPTY as [HNOEMPTY1 [HNOEMPTY2 HNOEMPTY3]].
  (* Use inrange2_disjoint! *)
  destruct (disjoint_ranges ((b1,l1)::(b2,l2)::nil)) eqn:HDISJ12;
  destruct (disjoint_ranges ((b1,l1)::(b3,l3)::nil)) eqn:HDISJ13.
  - (* Okay, (b1, l1), (b2, l2) are disjoint. *)
    assert (H12:(b1 + l1 = b2 /\ i = b2) \/ (b2 + l2 = b1 /\ i = b1)).
    { apply inrange2_disjoint; assumption. }
    (* (b1, l1), (b3, l3) are also disjoint. *)
    assert (H13:(b1 + l1 = b3 /\ i = b3) \/ (b3 + l3 = b1 /\ i = b1)).
    { apply inrange2_disjoint; assumption. }
    (* Prettify *)
    unfold in_range in *.
    simpl in *.
    repeat (rewrite andb_true_iff in *).
    repeat (rewrite andb_true_r in *).
    repeat (rewrite Nat.leb_le in *).
    repeat (rewrite Nat.ltb_lt in *).
    destruct H12 as [H12 | H12];
    destruct H12 as [H12 H12'];
    destruct H13 as [H13 | H13];
    destruct H13 as [H13 H13'].
    + assert (disjoint_range (b2, l2) (b3, l3) = false).
      { apply disjoint_same. assumption. assumption. congruence. }
      rewrite H. rewrite andb_false_r. auto.
    + assert (disjoint_range (b1, l1) (b2, l2) = false).
      { apply disjoint_same. assumption. assumption. congruence. }
      rewrite H. reflexivity.
    + assert (disjoint_range (b1, l1) (b3, l3) = false).
      { apply disjoint_same. assumption. assumption. congruence. }
      rewrite H. rewrite andb_false_r. auto.
    + assert (disjoint_range (b2, l2) (b3, l3) = false).
      { apply disjoint_same2. assumption. assumption. congruence. }
      rewrite H. rewrite andb_false_r. auto.
  - (* No, (b1, l1), (b3, l3) overlap. *)
    simpl in *.
    repeat (rewrite andb_true_r in *).
    rewrite HDISJ13. rewrite andb_false_r. auto.
  - (* No, (b1, l1), (b2, l2) overlap. *)
    simpl in *.
    repeat (rewrite andb_true_r in *).
    rewrite HDISJ12. auto.
  - (* (b1, l1) - (b3, l3) overlap, and (b1, l1) - (b2, l2) overlap too. *)
    simpl in *.
    repeat (rewrite andb_true_r in *).
    rewrite HDISJ12. auto.
Qed.

(* Theorem: If ranges are disjoint, there are at most 2 ranges
   which have number i in-range. *)
Theorem disjoint_includes_atmost_2:
  forall rs i rs' (HDISJ: disjoint_ranges rs = true)
         (HIN:rs' = disjoint_include rs i)
         (HNOZERO:no_empty_range rs = true),
    List.length rs' < 3.
Proof.
  intros.
  generalize dependent rs'.
  induction rs.
  - intros. simpl in HIN. rewrite HIN. simpl. auto.
  - intros.
    simpl in HDISJ.
    rewrite andb_true_iff in HDISJ. 
    simpl in HNOZERO.
    rewrite andb_true_iff in HNOZERO.
    destruct HDISJ as [HDISJ1 HDISJ2].
    destruct HNOZERO as [HNOZERO0 HNOZERO].
    simpl in HIN.
    destruct (in_range i a) eqn:HCOND.
    + (* New element fit. *)
      (* rs' is an updated range. *)
      destruct rs' as [| rs'h rs't].
      * inversion HIN.
      * inversion HIN.
        rewrite <- H0 in *.
        clear H0.
        destruct rs'h as [beg len].
        simpl in HCOND.
        assert (length rs't < 3).
        {
          apply IHrs; assumption.
        }
        (* rs't may be [], [(beg1,len1)], [(beg1,len1),(beg2,len2)]. *)
        destruct rs't as [ | rs'th rs'tt].
        { rewrite <- H1. simpl. auto. } (* [] *)
        destruct rs'th as [beg1 len1].
        destruct rs'tt as [ | rs'tth rs'ttt].
        { rewrite <- H1. simpl. auto. } (* [(beg1, len1)] *)
        destruct rs'tth as [beg2 len2].
        destruct rs'ttt as [ | rs'ttth rs'tttt].
        { (* [(beg1, len1), (beg2, len2)]. *)
          (* (beg1, len1), (beg2, len2) are in rs(all ranges) as well. *)
          assert (HDISJ0:forallb (fun r2 : nat * nat => disjoint_range (beg, len) r2)
                          ((beg1,len1)::(beg2,len2)::nil) = true).
          {
            apply lsubseq_forallb with (l := rs).
            assumption.
            rewrite H1.
            apply disjoint_include_lsubseq.
          }
          assert (HDISJ12: disjoint_ranges ((beg1, len1)::(beg2, len2)::nil) = true).
          {
            apply disjoint_lsubseq_disjoint with (rs := rs).
            assumption.
            rewrite H1.
            apply disjoint_include_lsubseq.
          }
          (* Okay, we got (beg, len) (beg1, len1) disjoint,
             (beg, len) (beg2, len2) disjoint. *)
          simpl in HDISJ0.
          rewrite andb_true_r in HDISJ0.
          rewrite andb_true_iff in HDISJ0.
          destruct HDISJ0 as [HDISJ01 HDISJ02].
          simpl in HDISJ12.
          repeat (rewrite andb_true_r in HDISJ12).
          (* Make in_range predicates. *)
          assert (HIN12: List.forallb (in_range i)
                                      ((beg1,len1)::(beg2,len2)::nil) = true).
          {
            rewrite H1.
            unfold disjoint_include.
            apply filter_forallb.
          }
          simpl in HIN12.
          repeat (rewrite andb_true_iff in HIN12).
          destruct HIN12 as [HIN1 [HIN2 _]].
          (* Non-zero-size range. *)
          assert (HNOZERO12: no_empty_range ((beg1,len1)::(beg2,len2)::nil) = true).
          {
            unfold no_empty_range.
            rewrite H1.
            apply lsubseq_forallb with (l := rs).
            apply HNOZERO. apply disjoint_include_lsubseq.
          }
          simpl in HNOZERO12.
          repeat (rewrite andb_true_iff in HNOZERO12).
          destruct HNOZERO12 as [HNOZERO1 [HNOZERO2 _]].
          (* Now, the main theorem. *)
          assert (HMAIN: disjoint_ranges
                           ((beg, len)::(beg1, len1)::(beg2, len2)::nil) = false).
          {
            apply inrange3_never_disjoint with (i := i).
            assumption. assumption. assumption.
            simpl. simpl in HNOZERO0.
            rewrite HNOZERO0. rewrite HNOZERO1. rewrite HNOZERO2.
            reflexivity.
          }
          (* Make False *)
          simpl in HMAIN.
          rewrite HDISJ01 in HMAIN.
          rewrite HDISJ02 in HMAIN.
          rewrite HDISJ12 in HMAIN.
          simpl in HMAIN.
          inversion HMAIN.
        }
        { (* disjoint_include already returned more than 2 ranges.
             This is impossible. *)
          simpl in H.
          exfalso.
          apply (Lt.le_not_lt 3 (3 + length rs'tttt)).
          repeat (apply le_n_S).
          apply le_0_n.
          apply H.
        }
   + (* No new range fit *)
     apply IHrs.
     assumption.
     assumption.
     assumption.
Qed.

(* If (b1, l1) (b2, l2) are disjoint,
   and i != b1 /\ i != b2,
   then i cannot belong to both ranges. *) 
Lemma inrange2_false:
  forall b1 l1 b2 l2 i
         (HDISJ:disjoint_ranges ((b1, l1)::(b2, l2)::nil) = true)
         (HNOTBEG:~(i = b1 \/ i = b2)),
    in_range i (b1,l1) && in_range i (b2, l2) = false.
Proof.
  intros.
  simpl in HDISJ.
  repeat (rewrite andb_true_r in HDISJ).
  unfold disjoint_range in HDISJ.
  rewrite orb_true_iff in HDISJ.
  repeat (rewrite Nat.leb_le in HDISJ).
  remember (in_range i (b1, l1)) as v1.
  remember (in_range i (b2, l2)) as v2.
  unfold in_range in *.
  simpl in *.
  destruct v1; destruct v2; try reflexivity.
  {
    symmetry in Heqv1.
    symmetry in Heqv2.
    rewrite andb_true_iff in *.
    repeat (rewrite Nat.leb_le in *).
    destruct HDISJ.
    - assert (i = b2).
      {
        apply Nat.le_antisymm.
        - apply Nat.le_trans with (m := b1 + l1).
          apply Heqv1. apply H.
        - apply Heqv2.
      }
      exfalso.
      apply HNOTBEG. right. assumption.
    - assert (i = b1).
      {
        apply Nat.le_antisymm.
        - apply Nat.le_trans with (m := b2 + l2).
          apply Heqv2. apply H.
        - apply Heqv1.
      }
      exfalso.
      apply HNOTBEG. left. assumption.
  }
Qed.

(**************************************************
             Number <-> bits (list bool)
 *************************************************)

Fixpoint pos_to_bits (n:positive): list bool :=
  match n with
  | xH => true::nil
  | xI n' => true::(pos_to_bits n')
  | xO n' => false::(pos_to_bits n')
  end.
Definition N_to_bits (n:N): list bool :=
  match n with
  | N0 => nil
  | Npos p => pos_to_bits p
  end.

Eval compute in N_to_bits 0%N. (* nil *)
Eval compute in N_to_bits 10%N. (* [f,t,f,t] *)

Fixpoint bits_to_pos (bits:list bool): positive :=
  match bits with
  | nil => xH
  | true::nil => xH
  | h::t => (if h then xI else xO) (bits_to_pos t)
  end.
Fixpoint bits_to_N (bits:list bool): N :=
  match bits with
  | nil => N0
  | _ => Npos (bits_to_pos bits)
  end.


Fixpoint erase_lzerobits (bits:list bool): list bool :=
  match bits with
  | nil => nil
  | h::t =>
    match h with | false => erase_lzerobits t | true => bits
    end
  end.

Definition erase_hzerobits (bits:list bool): list bool :=
  List.rev (erase_lzerobits (List.rev bits)).

Eval compute in bits_to_N nil. (* 0 *)
Eval compute in bits_to_N (true::false::true::nil). (* 5 *)
Eval compute in erase_hzerobits (false::false::true::false::nil).


Lemma pos_bits_pos:
  forall (p:positive), bits_to_pos (pos_to_bits p) = p.
Proof.
  intros.
  induction p.
  - simpl. rewrite IHp.
    destruct p; simpl; reflexivity.
  - simpl. rewrite IHp. reflexivity.
  - simpl. reflexivity.
Qed.

Lemma N_bits_N:
  forall (n:N), bits_to_N (N_to_bits n) = n.
Proof.
  intros.
  destruct n.
  - reflexivity.
  - simpl.
    assert (~ (pos_to_bits p = nil)).
    {
      intros H.
      destruct p; simpl in H; inversion H.
    }
    destruct (pos_to_bits p) eqn:HEQ.
    + exfalso. apply H. reflexivity.
    + unfold bits_to_N. rewrite <- HEQ. rewrite pos_bits_pos. reflexivity.
Qed.
