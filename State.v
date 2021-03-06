Require Import BinPos.
Require Import List.
Require Import Omega.
Require Import sflib.
Require Import Bool.

Require Import Common.
Require Import Lang.
Require Import Memory.
Require Import LoadStore.
Require Import Value.


Module Ir.

Module Regfile.
(* Definition of a register file. *)
Definition t := list (nat * Ir.val).

Definition get (rf:t) (regid:nat): option Ir.val :=
  match (list_find_key rf regid) with
  | nil => None
  | h::t => Some h.(snd)
  end.

Definition update (rf:t) (regid:nat) (v:Ir.val): t :=
  (regid,v)::rf.

(* Definition of two regfiles. *)
Definition eq (r1 r2:t): Prop :=
  forall regid, get r1 regid = get r2 regid.


(***************************************************
              Lemmas about Regfile.
 ***************************************************)

Theorem eq_refl:
  forall r, eq r r.
Proof.
  intros.
  unfold eq. intros. reflexivity.
Qed.

Theorem eq_symm:
  forall r1 r2 (HEQ:eq r1 r2), eq r2 r1.
Proof.
  intros.
  unfold eq in *. intros. congruence.
Qed.

Theorem update_eq:
  forall (r1 r2:t) (HEQ:eq r1 r2)
         (regid:nat) (v:Ir.val),
    eq (update r1 regid v) (update r2 regid v).
Proof.
  unfold eq in *.
  intros.
  unfold update.
  unfold get.
  simpl.
  destruct (regid =? regid0) eqn:Heqid.
  - simpl. reflexivity.
  - unfold get in HEQ.
    rewrite HEQ. reflexivity.
Qed.

Theorem update_reordered_eq:
  forall (rf1 rf2:t) (rid1 rid2:nat) (v1 v2:Ir.val)
         (HNEQ:Nat.eqb rid1 rid2 = false)
         (HEQ:eq rf1 rf2),
    eq (update (update rf1 rid1 v1) rid2 v2)
       (update (update rf2 rid2 v2) rid1 v1).
Proof.
  intros.
  unfold update.
  simpl.
  unfold eq.
  intros.
  unfold get.
  simpl.
  destruct (rid2 =? regid) eqn:Heqid2;
    destruct (rid1 =? regid) eqn:Heqid1;
    try (rewrite Nat.eqb_eq in *);
    try (rewrite Nat.eqb_neq in *).
  - omega.
  - reflexivity.
  - reflexivity.
  - unfold eq in HEQ. unfold get in HEQ.
    apply HEQ.
Qed.

Lemma get_update:
  forall rf r v,
    Ir.Regfile.get (Ir.Regfile.update rf r v) r = Some v.
Proof.
  intros.
  unfold Ir.Regfile.get.
  unfold Ir.Regfile.update.
  unfold list_find_key.
  simpl.
  rewrite PeanoNat.Nat.eqb_refl. reflexivity.
Qed.

Lemma get_update2:
  forall rf r1 r2 v (HDIFF:r1 <> r2),
    Ir.Regfile.get (Ir.Regfile.update rf r2 v) r1 =
    Ir.Regfile.get rf r1.
Proof.
  intros.
  unfold Ir.Regfile.get.
  unfold Ir.Regfile.update.
  unfold list_find_key.
  simpl.
  apply not_eq_sym in HDIFF.
  rewrite <- PeanoNat.Nat.eqb_neq in HDIFF.
  rewrite HDIFF. reflexivity.
Qed.

End Regfile.


Module Stack.

(* Definition of a call stack. *)
Definition t := list (Ir.callid * (Ir.IRFunction.pc * Regfile.t)).

Definition eq (s1 s2:t):Prop :=
  List.Forall2 (fun itm1 itm2 =>
                  itm1.(fst) = itm2.(fst) /\ itm1.(snd).(fst) = itm2.(snd).(fst) /\
                  Regfile.eq itm1.(snd).(snd) itm2.(snd).(snd))
               s1 s2.

(* Equality without PC. *)
Definition eq_wopc (s1 s2:t):Prop :=
  List.Forall2 (fun itm1 itm2 =>
                  itm1.(fst) = itm2.(fst) /\
                  Regfile.eq itm1.(snd).(snd) itm2.(snd).(snd))
               s1 s2.

Definition empty (s:t): bool :=
  match s with
  | [] => true
  | _ => false
  end.

(***************************************************
              Lemmas about Stack.
 ***************************************************)

Theorem eq_refl:
  forall s, eq s s.
Proof.
  intros.
  unfold eq.
  induction s.
  - constructor.
  - constructor. split. reflexivity. split. reflexivity. apply Regfile.eq_refl.
    assumption.
Qed.

Theorem eq_symm:
  forall s1 s2 (HEQ:eq s1 s2),
    eq s2 s1.
Proof.
  intros. unfold eq in *.
  induction HEQ.
  - intros. constructor.
  - desH H. constructor.
    split. congruence. split. congruence. apply Regfile.eq_symm. assumption.
    assumption.
Qed.

Theorem eq_wopc_refl:
  forall s, eq_wopc s s.
Proof.
  intros.
  unfold eq.
  induction s.
  - constructor.
  - constructor. split. reflexivity. apply Regfile.eq_refl.
    assumption.
Qed.

Theorem eq_wopc_trans:
  forall s1 s2 s3 (HEQ1:eq_wopc s1 s2) (HEQ2:eq_wopc s2 s3),
    eq_wopc s1 s3.
Proof.
  intros.
  unfold eq_wopc in *.
  generalize dependent s2.
  generalize dependent s3.
  induction s1.
  - intros. inv HEQ1. inv HEQ2. constructor.
  - intros. inv HEQ1. simpl in H1. desH H1.
    inv HEQ2. simpl in H4. desH H4. constructor.
    split. congruence. unfold Regfile.eq in *. intros. congruence.
    eapply IHs1. eassumption. eassumption.
Qed.

Theorem eq_eq_wopc:
  forall s1 s2 (HEQ:eq s1 s2),
    eq_wopc s1 s2.
Proof.
  intros.
  unfold eq in HEQ.
  unfold eq_wopc.
  induction HEQ.
  - constructor.
  - constructor.
    desH H.
    split. congruence. congruence.
    assumption.
Qed.

Theorem eq_wopc_symm:
  forall s1 s2 (HEQ:eq_wopc s1 s2),
    eq_wopc s2 s1.
Proof.
  intros. unfold eq_wopc in *.
  induction HEQ.
  - intros. constructor.
  - desH H. constructor.
    split. congruence. apply Regfile.eq_symm. assumption.
    assumption.
Qed.

End Stack.


Module Config.

Section CONFIG.

Variable md:Ir.IRModule.t.

(* Definition of a program state. *)
Structure t := mk
  {
    m:Ir.Memory.t; (* a memory *)
    s:Stack.t; (* a call stack *)
    cid_to_f:list (Ir.callid * nat); (*callid -> function id*)
    cid_fresh: Ir.callid; (* Fresh, unused call id. *)
  }.

(* Get register value. *)
Definition get_rval (c:t) (regid:nat): option Ir.val :=
  match c.(s) with
  | nil => None
  | (_, (_, r))::_ => Regfile.get r regid
  end.

(* Get value of the operand o. *)
Definition get_val (c:t) (o:Ir.op): option Ir.val:=
  match o with
  | Ir.opconst c => Some
    match c with
    | Ir.cnum cty cn => Ir.num cn
    | Ir.cnullptr cty => Ir.ptr Ir.NULL
    | Ir.cpoison cty => Ir.poison
    | Ir.cglb glbvarid => Ir.ptr (Ir.plog glbvarid 0)
    end
  | Ir.opreg regid => get_rval c regid
  end.



(* Wellformedness of a pointer value. *)
Definition ptr_wf (p:Ir.ptrval) (m:Ir.Memory.t):=
  (forall l ofs,
      p = Ir.plog l ofs ->
      (ofs < Ir.MEMSZ /\ exists mb, Ir.Memory.get m l = Some mb))
  /\
  (forall ofs I cid,
      p = Ir.pphy ofs I cid ->
      ofs < Ir.MEMSZ).

Definition ptr_in_byte (p:Ir.ptrval) ofs (b:Ir.Byte.t) :=
  Ir.Bit.baddr p ofs = b.(Ir.Byte.b0) \/
  Ir.Bit.baddr p ofs = b.(Ir.Byte.b1) \/
  Ir.Bit.baddr p ofs = b.(Ir.Byte.b2) \/
  Ir.Bit.baddr p ofs = b.(Ir.Byte.b3) \/
  Ir.Bit.baddr p ofs = b.(Ir.Byte.b4) \/
  Ir.Bit.baddr p ofs = b.(Ir.Byte.b5) \/
  Ir.Bit.baddr p ofs = b.(Ir.Byte.b6) \/
  Ir.Bit.baddr p ofs = b.(Ir.Byte.b7).

(* Wellformedness of a program state. *)
Structure wf (c:t) := mk_wf
  {
    (* wf_m: Memory is also well-formed. *)
    wf_m: Ir.Memory.wf c.(m);
    (* wf_cid_to_f: there's no duplicated
       call ids in cid_to_f. which is a mapping from
       CallID to Function name (= function id)
       *)
    wf_cid_to_f: List.NoDup (list_keys c.(cid_to_f));
    (* wf_cid_to_f2: All function ids in cid_to_f are valid, i.e.,
       has corresponding function definition. *)
    wf_cid_to_f2: forall cf (HIN:List.In cf c.(cid_to_f)),
        exists f, Ir.IRModule.getf cf.(snd) md = Some f;
    (* wf_stack: all PCs stored in the call stack (which is c.(s))
       are valid, respective to corresponding functions. *)
    wf_stack: forall curcid curpc funid f curregfile
                     (HIN:List.In (curcid, (curpc, curregfile)) c.(s))
                     (HIN2:List.In (curcid, funid) c.(cid_to_f))
                     (HF:Some f = Ir.IRModule.getf funid md),
        Ir.IRFunction.valid_pc curpc f = true;
    (* wf_ptr: regfile has only wellformed ptr *)
    wf_ptr:
      forall op p
             (HGETVAL:get_val c op = Some (Ir.ptr p)),
        ptr_wf p c.(m);
    (* wf_ptr_mem: memory has only wellformed ptr. *)
    wf_ptr_mem:
      forall bid mb byt ofs p
             (HBLK:Some mb = Ir.Memory.get c.(m) bid)
             (HBYTE:List.In byt (Ir.MemBlock.c mb))
             (HBIT:ptr_in_byte p ofs byt),
        ptr_wf p c.(m)
  }.


(* Update value of register regid. *)
Definition update_rval (c:t) (regid:nat) (v:Ir.val): t :=
  match c.(s) with
  | nil => c
  | (cid, (pc0, r))::s' =>
    mk c.(m) ((cid, (pc0, Regfile.update r regid v))::s') c.(cid_to_f) c.(cid_fresh)
  end.

(* Update memory. *)
Definition update_m (c:t) (m:Ir.Memory.t): t :=
  mk m c.(s) c.(cid_to_f) c.(cid_fresh).

(* Get function id (= function name) of cid. *)
Definition get_funid (c:t) (cid:Ir.callid): option nat :=
  match (list_find_key c.(cid_to_f) cid) with
  | nil => None
  | h::t => Some h.(snd)
  end.

(* Update PC into next_pc. *)
Definition update_pc (c:t) (next_pc:Ir.IRFunction.pc): t :=
  match c.(s) with
  | (cid, (pc0, r))::t => mk c.(m) ((cid,(next_pc, r))::t) c.(cid_to_f) c.(cid_fresh)
  | _ => c
  end.

(* Get (definition of the running function, PC inside the function). *)
Definition cur_fdef_pc (c:t): option (Ir.IRFunction.t * Ir.IRFunction.pc) :=
  match (s c) with
  | (cid, (pc0, _))::t =>
    match get_funid c cid with
    | Some funid =>
      match Ir.IRModule.getf funid md with
      | Some fdef => Some (fdef, pc0)
      | None => None
      end
    | None => None
    end
  | nil => None
  end.

(* Returns the instruction pc is pointing to. *)
Definition cur_inst (c:t): option (Ir.Inst.t) :=
  match cur_fdef_pc c with
  | Some (fdef, pc0) => Ir.IRFunction.get_inst pc0 fdef
  | None => None
  end.

(* Returns the instruction pc is pointing to. *)
Definition cur_phi (c:t): option (Ir.PhiNode.t) :=
  match cur_fdef_pc c with
  | Some (fdef, pc0) => Ir.IRFunction.get_phi pc0 fdef
  | None => None
  end.

(* Returns the terminator pc is pointing to. *)
Definition cur_terminator (c:t): option (Ir.Terminator.t) :=
  match (cur_fdef_pc c) with
  | Some (fdef, pc0)=> Ir.IRFunction.get_terminator pc0 fdef
  | _ => None
  end.

(* Returns true if the call stack has more than one entry, false otherwise. *)
Definition has_nestedcall (c:t): bool :=
  Nat.ltb 1 (List.length (s c)).


(* Definition of equality. *)
Definition eq (c1 c2:t): Prop :=
  c1.(m) = c2.(m) /\ Stack.eq c1.(s) c2.(s) /\ c1.(cid_to_f) = c2.(cid_to_f) /\
  c1.(cid_fresh) = c2.(cid_fresh).

(* Equality without PC. *)
Definition eq_wopc (c1 c2:t): Prop :=
  c1.(m) = c2.(m) /\ Stack.eq_wopc c1.(s) c2.(s) /\ c1.(cid_to_f) = c2.(cid_to_f) /\
  c1.(cid_fresh) = c2.(cid_fresh).

(* Equality without memory. *)
Definition eq_wom (c1 c2:t): Prop :=
  Stack.eq c1.(s) c2.(s) /\ c1.(cid_to_f) = c2.(cid_to_f) /\
  c1.(cid_fresh) = c2.(cid_fresh).


(***************************************************
              Lemmas about Config.
 ***************************************************)

Theorem eq_refl:
  forall c:t, eq c c.
Proof.
  intros.
  unfold eq.
  split. reflexivity. split. apply Stack.eq_refl.
  split; reflexivity.
Qed.

Theorem eq_wopc_refl:
  forall c:t, eq_wopc c c.
Proof.
  intros.
  unfold eq_wopc.
  split. reflexivity. split. apply Stack.eq_wopc_refl.
  split; reflexivity.
Qed.

Theorem eq_wopc_symm:
  forall c1 c2 (HEQ:eq_wopc c1 c2), eq_wopc c2 c1.
Proof.
  intros.
  unfold eq_wopc in *.
  desH HEQ.
  split. congruence. split. apply Stack.eq_wopc_symm. assumption.
  split; congruence.
Qed.

Theorem eq_wopc_trans:
  forall c1 c2 c3 (HEQ:eq_wopc c1 c2) (HEQ2:eq_wopc c2 c3),
  eq_wopc c1 c3.
Proof.
  intros.
  unfold eq_wopc in *.
  desH HEQ.
  desH HEQ2.
  split. congruence. split. eapply Stack.eq_wopc_trans. eassumption. assumption.
  split; congruence. 
Qed.

Lemma eq_wom_refl:
  forall st1,
    eq_wom st1 st1.
Proof.
  intros.
  split.
  { apply Ir.Stack.eq_refl.  }
  { split; congruence. }
Qed.

Lemma eq_wom_sym:
  forall st1 st2 (HEQ:eq_wom st1 st2),
    eq_wom st2 st1.
Proof.
  intros.
  inv HEQ.
  inv H0.
  split.
  { apply Ir.Stack.eq_symm. eassumption. }
  { split; congruence. }
Qed.

Lemma eq_wom_update_m:
  forall st1 st2 (HEQ:eq_wom st1 st2) m1 m2,
    eq_wom (update_m st1 m1) (update_m st2 m2).
Proof.
  intros.
  unfold update_m.
  inv HEQ.
  inv H0.
  unfold eq_wom.
  simpl.
  split. assumption.
  split; assumption.
Qed.

Theorem eq_update_rval:
  forall (c1 c2:t) (HEQ:eq c1 c2) r v,
    eq (update_rval c1 r v) (update_rval c2 r v).
Proof.
  intros.
  unfold eq in HEQ.
  destruct HEQ as [HEQ1 [HEQ2 [HEQ3 HEQ4]]].
  unfold eq.
  unfold update_rval.
  des_ifs; simpl.
  - split. assumption. split. congruence. split; congruence.
  - inversion HEQ2.
  - inversion HEQ2.
  - split. assumption. split.
    + unfold Stack.eq in *.
      inv HEQ2. simpl in H2.
      constructor. simpl.
      destruct H2 as [H21 [H22 H23]].
      split. congruence. split. congruence.
      apply Regfile.update_eq. assumption.
      assumption.
    + split. congruence. congruence.
Qed.

Theorem eq_wopc_update_rval:
  forall (c1 c2:t) (HEQ:eq_wopc c1 c2) r v,
    eq_wopc (update_rval c1 r v) (update_rval c2 r v).
Proof.
  intros.
  unfold eq_wopc in HEQ.
  destruct HEQ as [HEQ1 [HEQ2 [HEQ3 HEQ4]]].
  unfold eq_wopc.
  unfold update_rval.
  des_ifs; simpl.
  - split. assumption. split. congruence. split; congruence.
  - inversion HEQ2.
  - inversion HEQ2.
  - split. assumption. split.
    + unfold Stack.eq_wopc in *.
      inv HEQ2. simpl in H2.
      constructor. simpl.
      destruct H2 as [H21 H22].
      split. congruence.
      apply Regfile.update_eq. assumption.
      assumption.
    + split. congruence. congruence.
Qed.

Theorem eq_update_pc:
  forall (c1 c2:t) (HEQ:eq c1 c2) p,
    eq (update_pc c1 p) (update_pc c2 p).
Proof.
  intros.
  assert (HEQ_copy := HEQ).
  unfold eq in HEQ.
  destruct HEQ as [HEQ1 [HEQ2 [HEQ3 HEQ4]]].
  unfold Stack.eq in HEQ2.
  unfold update_pc.
  des_ifs; try (inversion HEQ2; fail).
  inv HEQ2. simpl in H2. desH H2.
  rewrite H2 in *. clear H2.
  rewrite H0 in *. clear H0.
  split; simpl.
  - assumption.
  - split. unfold Stack.eq. constructor.
    simpl. split. reflexivity. split. reflexivity. assumption.
    assumption.
    split. assumption. assumption.
Qed.

Theorem eq_wopc_update_pc:
  forall (c1 c2:t) (HEQ:eq_wopc c1 c2) p,
    eq_wopc (update_pc c1 p) (update_pc c2 p).
Proof.
  intros.
  assert (HEQ_copy := HEQ).
  unfold eq in HEQ.
  destruct HEQ as [HEQ1 [HEQ2 [HEQ3 HEQ4]]].
  unfold Stack.eq_wopc in HEQ2.
  unfold update_pc.
  des_ifs; try (inversion HEQ2; fail).
  inv HEQ2. simpl in H2. desH H2.
  rewrite H2 in *. clear H2.
  split; simpl.
  - assumption.
  - split. unfold Stack.eq_wopc. constructor.
    simpl. split. reflexivity. assumption.
    assumption.
    split. assumption. assumption.
Qed.

Theorem eq_get_funid:
  forall (c1 c2:t) (HEQ:eq c1 c2) cid,
    get_funid c1 cid = get_funid c2 cid.
Proof.
  intros.
  unfold eq in HEQ.
  desH HEQ.
  unfold get_funid. rewrite HEQ1. reflexivity.
Qed.

Theorem eq_wopc_get_funid:
  forall (c1 c2:t) (HEQ:eq_wopc c1 c2) cid,
    get_funid c1 cid = get_funid c2 cid.
Proof.
  intros.
  unfold eq_wopc in HEQ.
  desH HEQ.
  unfold get_funid. rewrite HEQ1. reflexivity.
Qed.


Theorem cur_fdef_pc_eq:
  forall (c1 c2:t) (HEQ:eq c1 c2),
    cur_fdef_pc c1 = cur_fdef_pc c2.
Proof.
  intros.
  assert (HEQ_copy := HEQ).
  unfold eq in HEQ.
  unfold cur_fdef_pc.
  desH HEQ.
  unfold Stack.eq in HEQ0.
  des_ifs; try (inversion HEQ0; fail);
    inv HEQ0; simpl in H2; desH H2.
  - rewrite H2 in *. clear H2.
    rewrite H0 in *. clear H0.
    rewrite eq_get_funid with (c2 := c2) in Heq0. congruence.
    assumption.
  - rewrite eq_get_funid with (c2 := c2) in Heq0 by assumption.
    congruence.
  - rewrite eq_get_funid with (c2 := c2) in Heq0 by assumption.
    congruence.
  - rewrite eq_get_funid with (c2 := c2) in Heq0 by assumption.
    congruence.
  - rewrite eq_get_funid with (c2 := c2) in Heq0 by assumption.
    congruence.
Qed.


Lemma cur_fdef_pc_update_pc:
  forall c p fdef p0
         (HPREV:cur_fdef_pc c = Some (fdef, p0)),
    cur_fdef_pc (update_pc c p) = Some (fdef, p).
Proof.
  intros.
  unfold cur_fdef_pc in *.
  unfold update_pc.
  des_ifs; simpl in *; inversion Heq; rewrite H0 in *;
    unfold get_funid in *;
    unfold cid_to_f in *; congruence.
Qed.
    
Lemma cur_fdef_pc_update_rval:
  forall c r v,
    cur_fdef_pc (update_rval c r v) =
         cur_fdef_pc c.
Proof.
  intros.
  unfold cur_fdef_pc.
  unfold update_rval.
  des_ifs; try congruence;
  try(simpl in *; inv Heq; unfold get_funid in *; simpl in *;
    congruence).
Qed.

Lemma cid_to_f_In_get_funid:
  forall curcid funid0 c
         (HWF:wf c)
         (HIN:In (curcid, funid0) (cid_to_f c)),
    Some funid0 = get_funid c curcid.
Proof.
  intros.
  inversion HWF.
  unfold get_funid.
  remember (list_find_key (cid_to_f c) curcid) as res.
  assert (List.length res < 2).
  { eapply list_find_key_NoDup.
    eassumption. eassumption. }
  assert (List.In (curcid, funid0) res).
  { rewrite Heqres. eapply list_find_key_In.
    eassumption. }
  destruct res; try (inversion H0; fail).
  destruct res.
  - inversion H0. rewrite H1. reflexivity. inversion H1.
  - simpl in H. omega.
Qed.

Lemma update_rval_update_m:
  forall m st r v,
    update_rval (update_m st m) r v =
    update_m (update_rval st r v) m.
Proof.
  intros.
  unfold update_rval.
  unfold update_m.
  simpl. des_ifs. rewrite Heq. reflexivity.
Qed.

Lemma update_rval_diffval:
  forall st r v1 v2
         (HDIFF:v1 <> v2) (HNOTEMPTY:Ir.Stack.empty (s st) = false),
    update_rval st r v1 <> update_rval st r v2.
Proof.
  intros.
  unfold update_rval.
  unfold Ir.Stack.empty in HNOTEMPTY.
  destruct (s st) eqn:HS.
  - congruence.
  - destruct p. destruct p.
    intros H0.
    inv H0. congruence.
Qed.

Lemma get_funid_update_m:
  forall st m cid,
    get_funid (update_m st m) cid =
    get_funid st cid.
Proof.
  intros.
  unfold get_funid.
  unfold update_m.
  simpl. reflexivity.
Qed.

Lemma cur_fdef_pc_update_m:
  forall m st,
    cur_fdef_pc (update_m st m) =
    cur_fdef_pc st.
Proof.
  intros.
  unfold cur_fdef_pc.
  unfold update_m. simpl.
  unfold update_rval.
  unfold update_m.
  simpl. des_ifs.
Qed.

Lemma update_pc_update_m:
  forall m st pc,
    update_pc (update_m st m) pc =
    update_m (update_pc st pc) m.
Proof.
  intros.
  unfold update_pc.
  unfold update_m.
  simpl. des_ifs. rewrite Heq. reflexivity.
Qed.

Lemma stack_eq_wopc_update_pc1:
  forall st1 st2 pc1
         (HEQ:Stack.eq_wopc (s st1) (s st2)),
    Stack.eq_wopc (s (update_pc st1 pc1)) (s st2).
Proof.
  intros.
  unfold update_pc.
  inv HEQ.
  - rewrite <- H0. constructor.
  - desH H1.
    des_ifs.
    simpl. constructor.
    simpl. split; assumption. assumption.
Qed.

Lemma stack_eq_wopc_update_pc2:
  forall st1 st2 pc2
         (HEQ:Stack.eq_wopc (s st1) (s st2)),
    Stack.eq_wopc (s st1) (s (update_pc st2 pc2)).
Proof.
  intros.
  unfold update_pc.
  inv HEQ.
  - rewrite <- H. constructor.
  - desH H1.
    des_ifs.
    simpl. constructor.
    simpl. split; assumption. assumption.
Qed.

Lemma cur_inst_update_rval:
  forall st r v,
    cur_inst (update_rval st r v) =
    cur_inst st.
Proof.
  intros.
  unfold cur_inst.
  rewrite cur_fdef_pc_update_rval. reflexivity.
Qed.

Lemma update_pc_update_rval:
  forall st r v p,
    update_pc (update_rval st r v) p =
    update_rval (update_pc st p) r v.
Proof.
  intros.
  unfold update_pc.
  unfold update_rval.
  des_ifs; simpl in *.
  inv Heq1. inv Heq. reflexivity.
Qed.

Lemma cur_inst_update_m:
  forall st m,
    cur_inst (update_m st m) =
    cur_inst st.
Proof.
  intros.
  unfold cur_inst.
  unfold cur_fdef_pc.
  unfold update_m.
  des_ifs.
Qed.

Lemma get_val_update_m:
  forall st m opv,
    get_val (update_m st m) opv =
    get_val st opv.
Proof.
  intros.
  unfold get_val.
  unfold get_rval.
  unfold update_m.
  simpl. reflexivity.
Qed.

Lemma get_val_update_pc:
  forall r pc0 st,
    get_val (update_pc st pc0) r =
    get_val st r.
Proof.
  unfold update_pc. unfold get_val.
  unfold get_rval. intros. des_ifs.
  congruence. simpl in Heq. inv Heq. reflexivity.
Qed.

Lemma m_update_pc:
  forall pc0 st,
    m (update_pc st pc0) =
    m st.
Proof.
  unfold update_pc. intros.
  des_ifs.
Qed.

Lemma eq_wopc_update_m:
  forall m st1 st2 (HEQ:eq_wopc st1 st2),
    eq_wopc (update_m st1 m) (update_m st2 m).
Proof.
  intros.
  inv HEQ.
  desH H0.
  split.
  - unfold update_m. reflexivity.
  - split. assumption. split. assumption. assumption.
Qed.

Lemma m_update_m:
  forall st m0,
    m (update_m st m0) = m0.
Proof.
  intros.
  unfold update_m. reflexivity.
Qed.

Lemma s_update_m:
  forall c t,
    s (update_m c t) = s c.
Proof.
  reflexivity.
Qed.

Lemma get_rval_update_rval_id:
  forall st r v
         (HSTACK:s st <> nil),
    get_rval (update_rval st r v) r = Some v.
Proof.
  intros.
  unfold get_rval.
  unfold update_rval.
  des_ifs. simpl in Heq. inv Heq.
  rewrite Ir.Regfile.get_update. reflexivity.
Qed.

Lemma cur_inst_not_cur_terminator:
  forall i st
         (HCUR:Some i = cur_inst st),
    None = cur_terminator st.
Proof.
  intros.
  unfold cur_inst in HCUR.
  unfold cur_terminator.
  des_ifs.
  unfold Ir.IRFunction.get_inst in HCUR.
  unfold Ir.IRFunction.get_terminator.
  des_ifs.
  rewrite PeanoNat.Nat.ltb_lt in Heq2.
  rewrite PeanoNat.Nat.eqb_eq in Heq1.
  omega.
Qed.

Lemma cur_inst_not_cur_phi:
  forall i st
         (HCUR:Some i = cur_inst st),
    None = cur_phi st.
Proof.
  intros.
  unfold cur_inst in HCUR.
  unfold cur_phi.
  des_ifs.
  unfold Ir.IRFunction.get_inst in HCUR.
  unfold Ir.IRFunction.get_phi.
  des_ifs.
Qed.



End CONFIG.

End Config.

End Ir.
