Require Import ZArith Znumtheory.
Require Import Coq.Lists.List.
Require Import Lia.
Import ListNotations.

Module SublistInternalLib.
(* Things copied from VST, to avoid dependencies *)
Ltac inv H := inversion H; clear H; subst.

Lemma if_true: forall (A: Prop) (E: {A}+{~A}) (T: Type) (B C: T), A -> (if E then B else C) = B.
Proof.
intros.
destruct E; auto.
contradiction.
Qed.

Lemma if_false: forall (A: Prop) (E: {A}+{~A}) (T: Type) (B C: T), ~A -> (if E then B else C) = C.
Proof.
intros.
destruct E; auto.
contradiction.
Qed.

Tactic Notation "if_tac" := 
  match goal with |- context [if ?a then _ else _] =>
    lazymatch type of a with
    | sumbool _ _ =>destruct a as [?H | ?H]
    | bool => fail "Use simple_if_tac instead of if_tac, since your expression"a" has type bool"
    | ?t => fail "Use if_tac only for sumbool; your expression"a" has type" t
   end end.

Tactic Notation "if_tac" "in" hyp(H0)
 := match type of H0 with context [if ?a then _ else _] =>
    lazymatch type of a with
    | sumbool _ _ =>destruct a as [?H | ?H]
    | bool => fail "Use simple_if_tac instead of if_tac, since your expression"a" has type bool"
    | ?t => fail "Use if_tac only for sumbool; your expression"a" has type" t
   end end.

Tactic Notation "forget" constr(X) "as" ident(y) :=
   set (y:=X) in *; clearbody y.

Lemma Zmin_spec:
  forall x y, Z.min x y = if Z_lt_dec x y then x else y.
Proof.
  intros. destruct (Zmin_spec x y); destruct H as [H H0]; rewrite H0; clear H0; destruct (Z_lt_dec x y); lia.
Qed.

Lemma Zmax_spec:
  forall x y, Z.max x y = if Z_lt_dec y x then x else y.
Proof.
  intros. destruct (Zmax_spec x y); destruct H as [H H0]; rewrite H0; clear H0; destruct (Z_lt_dec y x); lia.
Qed.

End SublistInternalLib.
Import SublistInternalLib.

Class Inhabitant (A: Type) := default : A.

#[(*export, after Coq 8.13*)global] Instance Inhabitant_Z : Inhabitant Z := 0.
#[(*export, after Coq 8.13*)global] Instance Inhabitant_nat : Inhabitant nat := O.
#[(*export, after Coq 8.13*)global] Instance Inhabitant_positive : Inhabitant positive := 1%positive.
#[(*export, after Coq 8.13*)global] Instance Inhabitant_list {T: Type} : Inhabitant (list T) := @nil T.
#[(*export, after Coq 8.13*)global] Instance Inhabitant_fun {T1 T2: Type} {H: Inhabitant T2} : Inhabitant (T1->T2) := fun _ => H.
#[(*export, after Coq 8.13*)global] Instance Inhabitant_Prop : Inhabitant Prop := False.
#[(*export, after Coq 8.13*)global] Instance Inhabitant_bool : Inhabitant bool := false.
#[(*export, after Coq 8.13*)global] Instance Inhabitant_pair {T1 T2 : Type} {x1: Inhabitant T1} {x2: Inhabitant T2} : Inhabitant (T1*T2)%type := (x1,x2).
#[(*export, after Coq 8.13*)global] Instance Inhabitant_option {A} : Inhabitant (option A) := None.


Lemma Zlength_length:
  forall A (al: list A) (n: Z),
    0 <= n ->
    (Zlength al = n <-> length al = Z.to_nat n).
Proof.
intros. rewrite Zlength_correct.
split; intro.
rewrite <- (Z2Nat.id n) in H0 by lia.
apply Nat2Z.inj in H0; auto.
lia.
Qed.

Lemma firstn_app1: forall {A} n (p l: list A),
  (n <= Datatypes.length p)%nat ->
   firstn n (p ++ l) = firstn n p.
Proof. intros A n.
induction n; simpl; intros. trivial.
  destruct p; simpl in H. lia.
  apply le_S_n in H. simpl. f_equal. auto.
Qed.

Lemma firstn_app2: forall {A} (n: nat) (al bl: list A),
 (n >= length al)%nat ->
 firstn n (al++bl) = al ++ firstn (n - length al) bl.
Proof.
intros. revert al H.
induction n; destruct al; intros.
reflexivity.
inv H.
simpl.
destruct bl; auto.
simpl.
f_equal. apply IHn.
simpl in H; lia.
Qed.

Lemma firstn_repeat {A} (v:A): forall i k, (i<=k)%nat ->
      firstn i (repeat v k) = repeat v i.
Proof.
  induction i; simpl; trivial; intros.
  destruct k. lia. simpl. rewrite IHi; trivial. lia.
Qed.

Lemma firstn_app:
 forall {A} n m (al: list A), firstn n al ++ firstn m (skipn n al) =
  firstn (n+m) al.
Proof. induction n; destruct al; intros; simpl; auto.
destruct m; reflexivity.
f_equal; auto.
Qed.

Lemma nth_skipn:
  forall {A} i n data (d:A),
       nth i (skipn n data) d = nth (i+n) data d.
Proof.
intros.
revert i data; induction n; simpl; intros.
f_equal; lia.
destruct data; auto.
destruct i; simpl; auto.
rewrite IHn.
replace (i + S n)%nat with (S (i + n))%nat by lia; auto.
Qed.

Lemma skipn_skipn: forall {A} n m (xs: list A),
  skipn n (skipn m xs) = skipn (m + n) xs.
Proof.
  intros.
  revert xs; induction m; intros.
  + reflexivity.
  + simpl.
    destruct xs.
    - destruct n; reflexivity.
    - apply IHm.
Qed.

Lemma firstn_exact_length: forall {A} (xs: list A), firstn (length xs) xs = xs.
Proof.
  intros.
  induction xs.
  + reflexivity.
  + simpl.
    rewrite IHxs.
    reflexivity.
Qed.

Lemma skipn_exact_length: forall {A} (xs: list A), skipn (length xs) xs = nil.
Proof.
  intros.
  induction xs.
  + reflexivity.
  + simpl.
    rewrite IHxs.
    reflexivity.
Qed.

Lemma len_le_1_rev: forall {A} (contents: list A),
  (length contents <= 1)%nat ->
  contents = rev contents.
Proof.
  intros.
  destruct contents.
  + reflexivity.
  + destruct contents.
    - reflexivity.
    - simpl in H. lia.
Qed.

Lemma firstn_firstn: forall {A} (contents: list A) n m,
  (n <= m)%nat ->
  firstn n (firstn m contents) = firstn n contents.
Proof.
  intros.
  revert n m H;
  induction contents;
  intros.
  + destruct n, m; reflexivity.
  + destruct n, m; try solve [lia].
    - simpl; reflexivity.
    - simpl; reflexivity.
    - simpl.
      rewrite IHcontents by lia.
      reflexivity.
Qed.

Lemma firstn_1_skipn: forall {A} n (ct: list A) d,
  (n < length ct)%nat ->
  nth n ct d :: nil = firstn 1 (skipn n ct).
Proof.
  intros.
  revert ct H; induction n; intros; destruct ct.
  + simpl in H; lia.
  + simpl. reflexivity.
  + simpl in H; lia.
  + simpl in H |- *.
    rewrite IHn by lia.
    reflexivity.
Qed.

Lemma skipn_length: forall {A} (contents: list A) n,
  length (skipn n contents) = (length contents - n)%nat.
Proof.
  intros.
  revert n;
  induction contents;
  intros.
  + destruct n; reflexivity.
  + destruct n; simpl.
    - reflexivity.
    - apply IHcontents.
Qed.

Lemma nth_firstn: forall {A} (contents: list A) n m d,
  (n < m)%nat ->
  nth n (firstn m contents) d = nth n contents d.
Proof.
  intros.
  revert n m H;
  induction contents;
  intros.
  + destruct n, m; reflexivity.
  + destruct n, m; try lia.
    - simpl. reflexivity.
    - simpl. apply IHcontents. lia.
Qed.

Lemma skipn_length_short:
  forall {A} n (al: list A),
    (length al <= n)%nat ->
    (length (skipn n al) = 0)%nat.
Proof.
 induction n; destruct al; simpl; intros; auto.
 lia.
 apply IHn. lia.
Qed.

Lemma skipn_short:
   forall {A} n (al: list A), (n >= length al)%nat -> skipn n al = nil.
Proof.
intros.
pose proof (skipn_length_short n al).
assert (length al <= n)%nat by auto.
specialize (H0 H1).
destruct (skipn n al); inv H0; auto.
Qed.

Lemma nth_map':
  forall {A B} (f: A -> B) d d' i al,
  (i < length al)%nat ->
   nth i (map f al) d = f (nth i al d').
Proof.
induction i; destruct al; simpl; intros; try lia; auto.
apply IHi; lia.
Qed.


Lemma skipn_nil: forall A n, skipn n (@nil A) = nil.
Proof. induction n; simpl; auto.
Qed.

Lemma skipn_drop:
 forall A n m (al: list A), skipn n (skipn m al) = skipn (n+m) al.
Proof.
induction m; intros.
* simpl; auto. f_equal; lia.
* replace (n + S m)%nat with (S (n + m))%nat by lia.
  destruct al; [ rewrite skipn_nil; auto | ].
  unfold skipn at 3; fold skipn.
 rewrite <- IHm.
 f_equal.
Qed.

Lemma skipn_app1:
 forall A n (al bl: list A),
  (n <= length al)%nat ->
  skipn n (al++bl) = skipn n al ++ bl.
Proof.
intros. revert al H;
induction n; destruct al; intros; simpl in *; try lia; auto.
apply IHn; lia.
Qed.

Lemma skipn_app2:
 forall A n (al bl: list A),
  (n >= length al)%nat ->
  skipn n (al++bl) = skipn (n-length al) bl.
Proof.
intros. revert al H;
induction n; destruct al; intros; simpl in *; try lia; auto.
apply IHn; lia.
Qed.

Lemma firstn_same:
  forall A n (b: list A), (n >= length b)%nat -> firstn n b = b.
Proof.
induction n; destruct b; simpl; intros; auto.
inv H.
f_equal; auto.
apply IHn.
lia.
Qed.

Lemma nth_firstn_low:
 forall A i n al (d: A),
  (i < n <= length al)%nat -> nth i (firstn n al) d = nth i al d.
Proof.
intros.
revert n al H; induction i; destruct n,al; simpl; intros; auto; try lia.
apply IHi; lia.
Qed.

Lemma nth_error_nth:
  forall A (d: A) i al, (i < length al)%nat -> nth_error al i = Some (nth i al d).
Proof.
induction i; destruct al; simpl; intros; auto.
inv H.
inv H.
apply IHi; lia.
Qed.

Lemma skipn_rev:
  forall {A} n (vl: list A),
   skipn n (rev vl) = rev (firstn (length vl - n) vl).
Proof.
induction n; intros.
simpl. rewrite Nat.sub_0_r. rewrite firstn_exact_length. auto.
destruct (rev vl) eqn:?.
pose proof (rev_length vl). rewrite Heql in H.
destruct vl; inv H. reflexivity.
simpl.
assert (vl = rev l ++ rev [a]).
rewrite <- rev_app_distr. simpl app. rewrite <- Heql; rewrite rev_involutive; auto.
rewrite H.
rewrite app_length.
simpl length.
rewrite <- (rev_involutive l) at 1.
rewrite IHn.
replace (length (rev l) + 1 - S n)%nat with (length (rev l) -n)%nat by lia.
f_equal.
rewrite firstn_app1 by lia.
reflexivity.
Qed.

Lemma Forall_repeat:
  forall {A} (P: A -> Prop) (n: nat) (a: A),
    P a -> Forall P (repeat a n).
Proof.
induction n; intros.
constructor.
constructor; auto.
Qed.

Lemma skipn_firstn: forall {A} n m (xs: list A),
  skipn n (firstn m xs) = firstn (m-n) (skipn n xs).
Proof.
intros.
revert xs n; induction m; intros.
simpl. destruct n; reflexivity.
destruct xs; simpl.
rewrite skipn_nil.
destruct match n with
            | O => S m
            | S l => (m - l)%nat
            end; reflexivity.
destruct n.
simpl. reflexivity.
simpl.
apply IHm.
Qed.

Lemma rev_skipn:
 forall {A} n (vl: list A),
  rev (skipn n vl) = firstn (length vl -n) (rev vl).
Proof.
induction n; intros.
simpl. rewrite Nat.sub_0_r.
rewrite <- rev_length.
rewrite firstn_exact_length.
auto.
destruct vl.
simpl. auto.
simpl.
rewrite IHn.
rewrite firstn_app1 by (rewrite rev_length; lia).
auto.
Qed.

Lemma firstn_skipn_rev:
  forall {A} lo n (vl: list A),
  (n+lo <= length vl)%nat ->
  firstn n (skipn lo (rev vl)) =
  rev (firstn n (skipn (length vl - (lo+n))%nat vl)).
Proof.
intros.
rewrite skipn_rev.
assert (n = (length vl - lo) - (length vl - (lo+n)))%nat by lia.
rewrite H0 at 2.
rewrite <- skipn_firstn.
rewrite rev_skipn.
rewrite firstn_length. rewrite min_l by lia.
f_equal.
auto.
Qed.

Lemma map_firstn:
  forall A B (F: A -> B) n (al: list A),
  map F (firstn n al) = firstn n (map F al).
Proof.
induction n; destruct al; simpl; intros; auto.
f_equal; auto.
Qed.

Lemma map_skipn:
  forall A B (F: A -> B) n (al: list A),
  map F (skipn n al) = skipn n (map F al).
Proof.
induction n; destruct al; simpl; intros; auto.
Qed.

Lemma Zlength_repeat:
  forall {A} n (x: A),
  0 <= n ->
  Zlength (repeat x (Z.to_nat n)) = n.
Proof.
intros.
rewrite Zlength_correct.
rewrite repeat_length.
apply Z2Nat.id; auto.
Qed.

Definition Zrepeat {A : Type} (x : A) (n : Z) : list A :=
  repeat x (Z.to_nat n).

Lemma Zlength_Zrepeat : forall (A : Type) (x : A) (n : Z),
  0 <= n ->
  Zlength (Zrepeat x n) = n.
Proof. intros *. unfold Zrepeat. apply @Zlength_repeat. Qed.

Lemma Zlength_app: forall T (al bl: list T),
    Zlength (al++bl) = Zlength al + Zlength bl.
Proof. induction al; intros. simpl app; rewrite Zlength_nil; lia.
 simpl app; repeat rewrite Zlength_cons; rewrite IHal; lia.
Qed.

Lemma Zlength_rev: forall T (vl: list T), Zlength (rev vl) = Zlength vl.
Proof. induction vl; simpl; auto. rewrite Zlength_cons. rewrite <- IHvl.
rewrite Zlength_app. rewrite Zlength_cons. rewrite Zlength_nil; lia.
Qed.

Lemma Zlength_map: forall A B (f: A -> B) l, Zlength (map f l) = Zlength l.
Proof. induction l; simpl; auto. repeat rewrite Zlength_cons. f_equal; auto.
Qed.

Lemma ZtoNat_Zlength:
 forall {A} (l: list A), Z.to_nat (Zlength l) = length l.
Proof.
intros. rewrite Zlength_correct. apply Nat2Z.id.
Qed.
#[export] Hint Rewrite @ZtoNat_Zlength : norm.

Lemma Zlength_nonneg:
 forall {A} (l: list A), 0 <= Zlength l.
Proof.
intros. rewrite Zlength_correct. lia.
Qed.

Definition Zlength' := @Zlength.

Ltac pose_Zlength_nonneg1 T A :=
     lazymatch goal with
      | H:  0 <= @Zlength T A |- _ => idtac
      | H:  0 <= @Zlength T A /\ _ |- _ => idtac
      | |- _ => pose proof (@Zlength_nonneg T A)
     end;
     (* the next three lines are to avoid blowups in the change command *)
     let x := fresh "x" in set (x:= @Zlength T A) in *;
     let y := fresh "y" in set (y := @Zlength) in x;
     fold @Zlength' in y; subst y; subst x.

Ltac pose_Zlength_nonneg :=
 repeat
  match goal with
  | |- context [@Zlength ?T ?A] => pose_Zlength_nonneg1 T A
  | H: context [@Zlength ?T ?A] |- _ => pose_Zlength_nonneg1 T A
 end;
  unfold Zlength' in *.

Ltac old_list_solve := autorewrite with sublist; pose_Zlength_nonneg; lia.

Definition Znth {X}{d: Inhabitant X} n (xs: list X) :=
  if (Z_lt_dec n 0) then default else nth (Z.to_nat n) xs d.

Lemma Znth_map:
  forall {A:Type} {da: Inhabitant A}{B:Type}{db: Inhabitant B} i (f: A -> B) (al: list A),
  0 <= i < Zlength al ->
  Znth i (map f al)  = f (Znth i al).
Proof.
unfold Znth.
intros.
rewrite if_false by lia.
rewrite if_false by lia.
rewrite nth_map' with (d' := da); auto.
apply Nat2Z.inj_lt. rewrite Z2Nat.id by lia.
change (Inhabitant A) with A.
rewrite <- Zlength_correct. lia.
Qed.

#[export] Hint Rewrite 
   (@Znth_map Z _) (@Znth_map nat _) (@Znth_map positive _)
    using (auto; rewrite ?Zlength_map in *; lia) : sublist.

(* Add these in a later file where things are in scope ...
#[export] Hint Rewrite (Znth_map Int.zero) (Znth_map Vundef)
    using (auto; rewrite ?Zlength_map in *; lia) : sublist.
*)

Lemma Znth_succ: forall {A}{a: Inhabitant A} i lo (v: list A), Z.succ lo <= i -> Znth (i - lo) v = Znth (i - (Z.succ lo)) (skipn 1 v).
Proof.
  intros.
  unfold Znth.
  if_tac; [lia |].
  if_tac; [lia |].
  rewrite nth_skipn.
  f_equal.
  change 1%nat with (Z.to_nat 1).
  rewrite <- Z2Nat.inj_add by lia.
  f_equal.
  lia.
Qed.

Lemma Znth_0_cons {A}{a: Inhabitant A} l (v:A): Znth 0 (v::l) = v.
Proof. reflexivity. Qed.
#[export] Hint Rewrite @Znth_0_cons : sublist.

Lemma Znth_pos_cons {A}{a: Inhabitant A} i l (v:A): 0<i -> Znth i (v::l) = Znth (i-1) l.
Proof. intros. unfold Znth. if_tac. lia. if_tac. lia.
  assert (Z.to_nat i = S (Z.to_nat (i-1))).
    rewrite <- Z2Nat.inj_succ. assert (i = Z.succ (i - 1)). lia. rewrite <- H2. trivial. lia.
  rewrite H2; reflexivity.
Qed.

Lemma Znth_In : forall {A}{a: Inhabitant A} i l, 0 <= i < Zlength l -> In (Znth i l) l.
Proof.
  intros; unfold Znth.
  destruct (Z_lt_dec i 0); [lia|].
  apply nth_In; rewrite Zlength_correct in *.
  apply Nat2Z.inj_lt; rewrite Z2Nat.id; lia.
Qed.

Lemma split3_full_length_list: forall {A}{a: Inhabitant A} lo mid hi (ct: list A),
  lo <= mid < hi ->
  Zlength ct = hi - lo ->
  ct = firstn (Z.to_nat (mid - lo)) ct ++
       (Znth (mid - lo) ct :: nil) ++
       skipn (Z.to_nat (mid - lo + 1)) ct.
Proof.
  intros.
  rewrite <- firstn_skipn with (l := ct) (n := Z.to_nat (mid - lo)) at 1.
  f_equal.
  rewrite Z2Nat.inj_add by lia.
  rewrite <- skipn_skipn.
  replace (Znth (mid - lo) ct :: nil) with (firstn (Z.to_nat 1) (skipn (Z.to_nat (mid - lo)) ct)).
  + rewrite firstn_skipn; reflexivity.
  + unfold Znth.
    if_tac; [lia |].
    rewrite firstn_1_skipn; [reflexivity |].
    rewrite <- (Nat2Z.id (length ct)).
    apply Z2Nat.inj_lt.
    - lia.
    - lia.
    - rewrite Zlength_correct in H0.
      lia.
Qed.

Lemma Forall_Znth:
 forall {A}{a: Inhabitant A} (F: A -> Prop) (al: list A) i,
   0 <= i < Zlength al ->
   Forall F al ->
   F (Znth i al).
Proof.
intros.
unfold Znth. rewrite if_false by lia.
rewrite Zlength_correct in H.
assert (Z.to_nat i < length al)%nat.
apply Nat2Z.inj_lt. rewrite Z2Nat.id by lia; lia.
clear H.
revert al H0 H1; induction (Z.to_nat i); destruct al; intros; simpl in *.
lia.
inv H0. auto.
inv H1.
inv H0.
apply IHn; auto.
lia.
Qed.

#[export] Hint Rewrite @app_nil_l @app_nil_r : sublist.

Lemma app_Znth1:
  forall A (a: Inhabitant A) (l l': list A) (i:Z),
  i < Zlength l -> Znth i (l++l') = Znth i l.
Proof.
intros.
unfold Znth.
if_tac; auto.
apply app_nth1.
apply Nat2Z.inj_lt. rewrite Z2Nat.id by lia.
rewrite Zlength_correct in H; auto.
Qed.

Lemma app_Znth2:
  forall A (a: Inhabitant A) (l l': list A) (i:Z),
  i >= Zlength l -> Znth i (l++l') = Znth (i-Zlength l) l'.
Proof.
intros.
unfold Znth.
pose proof (Zlength_nonneg l).
if_tac.
rewrite if_true by lia; auto.
rewrite if_false by lia.
rewrite app_nth2.
f_equal.
rewrite Z2Nat.inj_sub by auto.
rewrite Zlength_correct.
rewrite Nat2Z.id; auto.
apply Nat2Z.inj_ge. rewrite Z2Nat.id by lia.
rewrite <- Zlength_correct; auto.
Qed.

Lemma Znth_firstn:
  forall {A}{a: Inhabitant A} (al: list A) (n m : Z),
  n<m -> Znth n (firstn (Z.to_nat m) al) = Znth n al.
Proof.
intros.
unfold Znth.
if_tac; auto.
apply nth_firstn.
apply Z2Nat.inj_lt; lia.
Qed.

Lemma Znth_skipn: forall {A}{a: Inhabitant A}  i n xs,
  0 <= i ->
  0 <= n ->
  Znth i (skipn (Z.to_nat n) xs) = Znth (i+n) xs.
Proof.
  intros.
  unfold Znth.
  rewrite if_false by lia. rewrite if_false by lia.
  rewrite nth_skipn. f_equal.
  rewrite Z2Nat.inj_add by lia. auto.
Qed.

Lemma Z2Nat_neg: forall i, i < 0 -> Z.to_nat i = 0%nat.
Proof.
  intros.
  destruct i; try reflexivity.
  pose proof Zgt_pos_0 p; lia.
Qed.

Lemma Zlength_firstn:
  forall {A} n (v: list A), Zlength (firstn (Z.to_nat n) v) = Z.min (Z.max 0 n) (Zlength v).
Proof.
intros. rewrite !Zlength_correct.
rewrite firstn_length.
(* solve by SMT *)
rewrite Zmin_spec, Zmax_spec.
if_tac; [rewrite min_l | rewrite min_r].
if_tac.
rewrite Z2Nat_neg; auto.
apply Z2Nat.id; lia.
if_tac in H.
rewrite Z2Nat_neg; auto. lia.
rewrite <- (Nat2Z.id (length v)).
apply Z2Nat.inj_le; try lia.
auto.
if_tac in H; lia.
Qed.

Lemma Zlength_skipn:
  forall {A} n (v: list A),
  Zlength (skipn (Z.to_nat n) v) = Z.max 0 (Zlength v - (Z.max 0n)).
Proof.
intros.
(* solve by SMT *)
rewrite !Zlength_correct.
rewrite skipn_length. rewrite !Zmax_spec.
if_tac.
if_tac in H.
lia.
apply inj_minus2. apply Nat2Z.inj_gt. rewrite Z2Nat.id by lia.
lia.
if_tac.
rewrite (Z2Nat_neg n) by lia.
rewrite Nat.sub_0_r.
lia.
rewrite Nat2Z.inj_sub.
rewrite Z2Nat.id by lia. auto.
apply Nat2Z.inj_le.
rewrite Z2Nat.id by lia.  lia.
Qed.

Lemma Znth_cons:
 forall {A}(a: Inhabitant A)  i (al: list A) bl,
  0 <= i < Zlength al  ->
  Znth i al :: bl = firstn (Z.to_nat 1) (skipn (Z.to_nat i) al) ++ bl.
Proof.
intros.
pose proof (Znth_skipn 0 i al).
rewrite Z.add_0_l in H0.
rewrite <- H0 by lia; clear H0.
change (Znth 0 (skipn (Z.to_nat i) al) :: bl) with
   ([Znth 0 (skipn (Z.to_nat i) al)] ++ bl).
f_equal.
unfold Znth.
rewrite if_false  by lia.
assert (Zlength (skipn (Z.to_nat i) al) > 0).
rewrite Zlength_skipn.
rewrite (Z.max_r 0 i) by lia.
rewrite Z.max_r by lia.
lia.
destruct (skipn (Z.to_nat i) al).
rewrite Zlength_nil in H0; lia.
reflexivity.
Qed.

Lemma Zfirstn_app1:
 forall A n (al bl: list A),
  n <= Zlength al -> firstn (Z.to_nat n) (al++bl) = firstn (Z.to_nat n) al.
Proof.
intros.
apply firstn_app1.
apply Nat2Z.inj_le. rewrite Zlength_correct in H.
destruct (Z_lt_dec n 0).
rewrite Z2Nat_neg by auto. change (Z.of_nat 0) with 0; lia.
rewrite Z2Nat.id by lia.
lia.
Qed.

Lemma Zfirstn_same:
  forall A n (b: list A), n >= Zlength b -> firstn (Z.to_nat n) b = b.
Proof.
intros.
apply firstn_same.
rewrite Zlength_correct in H.
apply Nat2Z.inj_ge.
rewrite Z2Nat.id by lia.
auto.
Qed.

Lemma Zfirstn_app2: forall {A} n (al bl: list A),
 n >= Zlength al ->
 firstn (Z.to_nat n) (al++bl) = al ++ firstn (Z.to_nat (n - Zlength al)) bl.
Proof.
intros.
rewrite firstn_app2.
f_equal. f_equal.
rewrite Z2Nat.inj_sub.
rewrite Zlength_correct, Nat2Z.id. auto.
apply Zlength_nonneg.
apply Nat2Z.inj_ge.
rewrite Zlength_correct in H.
rewrite Z2Nat.id by lia.
auto.
Qed.

Lemma Zfirstn_firstn: forall {A} (contents: list A) n m,
  n <= m ->
  firstn (Z.to_nat n) (firstn (Z.to_nat m) contents) = firstn (Z.to_nat n) contents.
Proof.
intros.
destruct (Z_lt_dec n 0).
rewrite (Z2Nat_neg n) by lia.
reflexivity.
apply firstn_firstn.
apply Z2Nat.inj_le; lia.
Qed.
Lemma Zskipn_app1:
 forall A n (al bl: list A),
  n <= Zlength al ->
  skipn (Z.to_nat n) (al++bl) = skipn (Z.to_nat n) al ++ bl.
Proof.
intros.
apply skipn_app1.
rewrite Zlength_correct in H.
apply Nat2Z.inj_le.
destruct (Z_lt_dec n 0).
rewrite (Z2Nat_neg n) by lia.
change (Z.of_nat 0) with 0.  lia.
rewrite Z2Nat.id by lia.
auto.
Qed.

Lemma Zskipn_app2:
 forall A n (al bl: list A),
  n >= Zlength al ->
  skipn (Z.to_nat n) (al++bl) = skipn (Z.to_nat (n-Zlength al)) bl.
Proof.
intros.
rewrite Zlength_correct in *.
rewrite skipn_app2.
f_equal.
rewrite Z2Nat.inj_sub by lia.
rewrite Nat2Z.id.
auto.
apply Nat2Z.inj_ge.
destruct (Z_lt_dec n 0).
rewrite (Z2Nat_neg n) by lia.
change (Z.of_nat 0) with 0.  lia.
rewrite Z2Nat.id by lia.
auto.
Qed.

Lemma Znth_rev:
  forall {A}{d: Inhabitant A} i (al:list A),
  0 <= i < Zlength al ->
  Znth i (rev al) = Znth (Zlength al - i - 1) al.
Proof.
intros.
 unfold Znth. rewrite !if_false by lia.
rewrite !Z2Nat.inj_sub by lia.
rewrite Zlength_correct in*.
rewrite Nat2Z.id.
assert (Z.to_nat i < length al)%nat.
apply Nat2Z.inj_lt. rewrite Z2Nat.id by lia. lia.
change (Z.to_nat 1) with 1%nat.
clear H.
rewrite rev_nth; auto.
f_equal.
lia.
Qed.

Lemma Zskipn_firstn: forall {A} n m (xs: list A),
 0 <= n ->
 skipn (Z.to_nat n) (firstn (Z.to_nat m) xs) =
  firstn (Z.to_nat (m-n)) (skipn (Z.to_nat n) xs).
Proof.
intros.
rewrite skipn_firstn.
f_equal.
rewrite Z2Nat.inj_sub; auto.
Qed.

Lemma Zskipn_skipn: forall {A} n m (xs: list A),
  0 <= n -> 0 <= m ->
  skipn (Z.to_nat n) (skipn (Z.to_nat m) xs) = skipn (Z.to_nat (m + n)) xs.
Proof.
  intros.
  rewrite skipn_skipn.
 f_equal.
 rewrite Z2Nat.inj_add; auto.
Qed.

Lemma Zfirstn_app:
 forall {A} n m (al: list A),
  0 <= n -> 0 <= m ->
  firstn (Z.to_nat n) al ++ firstn (Z.to_nat m) (skipn (Z.to_nat n) al) =
  firstn (Z.to_nat (n+m)) al.
Proof.
intros.
rewrite firstn_app.
f_equal.
rewrite Z2Nat.inj_add; lia.
Qed.

Lemma Zfirstn_exact_length:
  forall {A} n (al: list A),
  n = Zlength al ->
  firstn (Z.to_nat n) al = al.
Proof.
intros.
subst.
rewrite Zlength_correct.
rewrite Nat2Z.id.
apply firstn_exact_length.
Qed.

(*****   SUBLIST  ******)

Definition sublist {A} (lo hi: Z) (al: list A) : list A :=
  skipn (Z.to_nat lo) (firstn (Z.to_nat hi) al).

Definition old_sublist {A} (lo hi: Z) (al: list A) : list A :=
  firstn (Z.to_nat (hi-lo)) (skipn (Z.to_nat lo) al).

Lemma sublist_old_sublist {A} (lo hi : Z) (al : list A) :
  0 <= lo ->
  sublist lo hi al = old_sublist lo hi al.
Proof.
  intros.
  unfold sublist, old_sublist.
  rewrite Z2Nat.inj_sub; auto.
  apply skipn_firstn_comm.
Qed.

Ltac unfold_sublist_old :=
  rewrite !sublist_old_sublist by lia; unfold old_sublist.

Definition upd_Znth {A} (i : Z) (al : list A) (x : A) : list A :=
  if Sumbool.sumbool_and _ _ _ _ (Z_le_gt_dec 0 i) (Z_lt_dec i (Zlength al)) then
    sublist 0 i al ++ x :: sublist (i+1) (Zlength al) al
  else
    al.

Definition old_upd_Znth {A} (i: Z) (al: list A) (x: A): list A :=
  sublist 0 i al ++ x :: sublist (i+1) (Zlength al) al.

Lemma upd_Znth_old_upd_Znth {A} (i : Z) (al : list A) (x : A) :
  0 <= i < Zlength al ->
  upd_Znth i al x = old_upd_Znth i al x.
Proof.
  intros.
  unfold upd_Znth, old_upd_Znth.
  if_tac; auto; lia.
Qed.

Ltac unfold_upd_Znth_old :=
  rewrite !upd_Znth_old_upd_Znth by (
    repeat rewrite Zlength_app;
    repeat rewrite Zlength_cons;
    pose_Zlength_nonneg;
    lia
  ); unfold old_upd_Znth.

Lemma upd_Znth_out_of_range : forall {A} i l (x : A),
  0 > i \/ i >= Zlength l ->
  upd_Znth i l x = l.
Proof.
  intros.
  unfold upd_Znth. if_tac; try lia.
  auto.
Qed.

Lemma sublist_sublist {A} i j k m (l:list A): 0<=m -> 0<=k <=i -> i <= j-m ->
  sublist k i (sublist m j l) = sublist (k+m) (i+m) l.
Proof.
  intros. unfold_sublist_old.
  rewrite skipn_firstn.
  rewrite firstn_firstn, skipn_skipn, <- Z2Nat.inj_add,(Z.add_comm _ k), Zminus_plus_simpl_r; trivial.
  lia.
  rewrite <- Z2Nat.inj_sub; trivial. apply Z2Nat.inj_le; try lia. lia.
Qed.

Lemma sublist_sublist' : forall {A} lo hi lo' hi' (al: list A),
  0 <= lo <= hi ->
  hi <= hi'-lo' ->
  0 <= lo' <= hi' ->
  hi' <= Zlength al ->
  sublist lo hi (sublist lo' hi' al) = sublist (lo+lo') (hi+lo') al.
Proof.
  intros.
  unfold_sublist_old.
  rewrite Zskipn_firstn by lia.
  rewrite Zfirstn_firstn by lia.
  rewrite Zskipn_skipn by lia.
  f_equal. f_equal. lia.
  f_equal. f_equal. lia.
Qed.

Lemma sublist_rejoin:
  forall {A} lo mid hi (al: list A),
  0 <= lo <= mid ->
  mid <= hi <= Zlength al ->
  sublist lo mid al ++ sublist mid hi al = sublist lo hi al.
Proof.
intros.
unfold_sublist_old.
replace (hi-lo) with ((mid-lo)+(hi-mid)) by lia.
rewrite <- Zfirstn_app by lia.
f_equal.
rewrite Zskipn_skipn by lia.
f_equal. f_equal. f_equal. lia.
Qed.

Lemma sublist_map:
  forall {A B} (F: A -> B) lo hi (al: list A),
  sublist lo hi (map F al) = map F (sublist lo hi al).
Proof.
intros.
unfold sublist.
rewrite map_skipn, map_firstn; auto.
Qed.

Lemma map_sublist:
  forall {A B} (F: A -> B) lo hi (al: list A),
  map F (sublist lo hi al) = sublist lo hi (map F al).
Proof.
intros.
symmetry. apply sublist_map.
Qed.

Lemma sublist_len_1:
  forall {A}{d: Inhabitant A} i (al: list A),
  0 <= i < Zlength al ->
  sublist i (i+1) al = Znth i al :: nil.
Proof.
  intros.
  unfold_sublist_old.
  replace (i+1-i) with 1 by lia.
  rewrite Znth_cons by lia.
  symmetry; apply app_nil_r.
Qed.

Lemma Znth_cons_sublist:
  forall {A}{d: Inhabitant A} i (al: list A) bl,
  0 <= i < Zlength al ->
  Znth i al :: bl = sublist i (i+1) al ++ bl.
Proof.
  intros.
  erewrite sublist_len_1 by eauto.
  reflexivity.
Qed.

Lemma Zlength_sublist:
  forall {A} lo hi (al: list A),
 0 <= lo <= hi -> hi <= Zlength al ->
 Zlength (sublist lo hi al) = hi-lo.
Proof.
intros.
unfold_sublist_old.
rewrite Zlength_firstn, Z.max_r by lia.
rewrite Zlength_skipn.
rewrite (Z.max_r 0 lo) by lia.
rewrite Z.max_r by lia.
rewrite Z.min_l by lia.
auto.
Qed.

Lemma sublist_same_gen:
forall {A} lo hi (al: list A),
  lo = 0 -> hi >= Zlength al ->
  sublist lo hi al = al.
Proof.
intros.
unfold_sublist_old; subst.
rewrite Z.sub_0_r.
simpl; rewrite firstn_all2; auto.
apply Nat2Z.inj_le.
pose proof (Zlength_nonneg al).
rewrite Z2Nat.id, <- Zlength_correct; lia.
Qed.

Lemma sublist_same:
forall {A} lo hi (al: list A),
  lo = 0 -> hi = Zlength al ->
  sublist lo hi al = al.
Proof.
intros; apply sublist_same_gen; lia.
Qed.

Lemma Znth_sublist:
  forall {A}{d: Inhabitant A} lo i hi (al: list A),
 0 <= lo ->
 0 <= i < hi-lo ->
 Znth i (sublist lo hi al) = Znth (i+lo) al.
Proof.
intros.
unfold_sublist_old.
rewrite Znth_firstn by lia.
rewrite Znth_skipn by lia. auto.
Qed.

Lemma rev_sublist:
  forall {A} lo hi (al: list A),
  0 <= lo <= hi -> hi <= Zlength al ->
  rev (sublist lo hi al) = sublist (Zlength al - hi) (Zlength al - lo) (rev al).
Proof.
intros.
unfold_sublist_old.
replace (skipn (Z.to_nat lo) al)
 with (skipn (length al - (Z.to_nat (Zlength al - hi) + (Z.to_nat (hi - lo)))) al).
rewrite <- firstn_skipn_rev.
f_equal.
f_equal. lia.
apply Nat2Z.inj_le.
rewrite Nat2Z.inj_add.
rewrite <- Zlength_correct.
rewrite !Z2Nat.id by lia.
lia.
f_equal.
apply Nat2Z.inj.
rewrite Nat2Z.inj_sub.
rewrite Nat2Z.inj_add.
rewrite !Z2Nat.id by lia.
rewrite <- Zlength_correct; lia.
apply Nat2Z.inj_le.
rewrite <- Zlength_correct.
rewrite Nat2Z.inj_add.
rewrite !Z2Nat.id by lia.
lia.
Qed.

Lemma sublist_nil:
  forall {A} lo (al: list A),
  sublist lo lo al = nil.
Proof.
intros.
unfold sublist.
rewrite skipn_firstn_comm.
rewrite Nat.sub_diag. reflexivity.
Qed.

Lemma Z_to_nat_monotone : forall n m,
  n <= m ->
  (Z.to_nat n <= Z.to_nat m)%nat.
Proof.
  intros.
  destruct n; destruct m; unfold Z.le in H; simpl in *; try lia.
  contradiction.
  apply Pos2Nat.inj_le. auto.
  contradiction.
Qed.

Lemma sublist_nil_gen : forall {A} (l : list A) i j, j <= i -> sublist i j l = [].
Proof.
  intros.
  unfold sublist.
  rewrite skipn_firstn_comm.
  assert (Z.to_nat j <= Z.to_nat i)%nat. apply Z_to_nat_monotone. auto.
  replace (Z.to_nat j - Z.to_nat i)%nat with O; auto.
  rewrite (proj2 (Nat.sub_0_le _ _)); auto.
Qed.

Lemma sublist_rev:
  forall {A} lo hi (al: list A),
  0 <= lo <= hi -> hi <= Zlength al ->
  sublist lo hi (rev al) = rev (sublist (Zlength al - hi) (Zlength al - lo) al).
Proof.
intros.
rewrite rev_sublist by lia.
f_equal; lia.
Qed.

Ltac pose_Zmin_irreducible :=
  match goal with
  | |- context [Z.min ?a ?b] =>
    pose proof (Zmin_irreducible a b)
  end.

Lemma sublist_app:
  forall {A} lo hi (al bl: list A),
  0 <= lo <= hi -> hi <= Zlength al + Zlength bl ->
  sublist lo hi (al++bl) =
  sublist (Z.min lo (Zlength al)) (Z.min hi (Zlength al)) al ++
  sublist (Z.max (lo-Zlength al) 0) (Z.max (hi-Zlength al) 0) bl.
Proof.
intros.
rewrite sublist_old_sublist by lia.
rewrite sublist_old_sublist by (pose_Zmin_irreducible; pose proof (Zlength_nonneg al); lia).
rewrite sublist_old_sublist by (apply Z.le_max_r).
unfold old_sublist.
destruct (Z_lt_dec hi (Zlength al)).
rewrite (Z.min_l hi (Zlength al)) by lia.
rewrite (Z.min_l lo (Zlength al)) by lia.
rewrite (Z.max_r (hi-Zlength al) 0) by lia.
rewrite (Z.max_r (lo-Zlength al) 0) by lia.
simpl firstn.
rewrite <- app_nil_end.
rewrite Zskipn_app1 by lia.
rewrite Zfirstn_app1
 by (rewrite Zlength_skipn, !Z.max_r; try lia;
      rewrite Z.max_r; lia).
auto.
rewrite (Z.min_r hi (Zlength al)) by lia.
rewrite (Z.max_l (hi-Zlength al) 0) by lia.
destruct (Z_lt_dec lo (Zlength al)).
rewrite (Z.min_l lo (Zlength al)) by lia.
rewrite (Z.max_r (lo-Zlength al) 0) by lia.
rewrite Zskipn_app1 by lia.
rewrite Zfirstn_app2
 by (rewrite Zlength_skipn, !Z.max_r; try lia;
      rewrite Z.max_r; lia).
rewrite Zlength_skipn, !Z.max_r; try lia;
      rewrite ?Z.max_r; try lia.
simpl skipn.
f_equal.

rewrite Zfirstn_exact_length; auto.
rewrite Zlength_skipn, !Z.max_r; try lia.
f_equal.
f_equal.
lia.
rewrite (Z.min_r lo (Zlength al)) by lia.
rewrite (Z.max_l (lo-Zlength al) 0) by lia.
rewrite Zskipn_app2 by lia.
rewrite Z.sub_diag.
simpl app.
f_equal.
f_equal.
lia.
Qed.

Lemma sublist_split:
  forall {A} lo mid hi (al: list A),
  0 <= lo <= mid ->
  mid <= hi <= Zlength al ->
  sublist lo hi al = sublist lo mid al ++ sublist mid hi al.
Proof.
intros.
symmetry; apply sublist_rejoin; auto.
Qed.

Lemma sublist_last_1 : forall {A}{d: Inhabitant A} lo hi (al : list A), 0 <= lo <= hi -> hi + 1 <= Zlength al ->
  sublist lo (hi + 1) al = sublist lo hi al ++ [Znth hi al].
Proof.
  intros.
  erewrite @sublist_split with (mid := hi) (hi := hi + 1), sublist_len_1; auto; lia.
Qed.

Lemma Zlen_le_1_rev:
 forall {A} (al: list A),
  Zlength al <= 1 -> rev al = al.
Proof.
intros.
symmetry.
apply len_le_1_rev.
apply Nat2Z.inj_le. rewrite <- Zlength_correct; apply H.
Qed.

Lemma skipn_0:
  forall A (l: list A), skipn 0 l = l.
Proof.
reflexivity.
Qed.

Lemma sublist_1_cons {A} l (v:A) n: sublist 1 n (v::l) = sublist 0 (n-1) l.
Proof.
  unfold_sublist_old. rewrite Z2Nat.inj_sub, skipn_0, Zminus_0_r. simpl. rewrite Z2Nat.inj_sub. trivial.
  lia. lia.
Qed.

Lemma sublist_nil': forall (A : Type) (lo lo': Z) (al : list A), lo=lo' -> sublist lo lo' al = [].
Proof. intros. subst. apply sublist_nil. Qed.

Lemma sublist_skip {A} (l:list A) i : 0<=i ->  sublist i (Zlength l) l = skipn (Z.to_nat i) l.
Proof. intros; unfold_sublist_old. apply firstn_same. rewrite skipn_length.
  rewrite Z2Nat.inj_sub, Zlength_correct, Nat2Z.id. lia. trivial.
Qed.

Lemma sublist_firstn {A} (l:list A) i: sublist 0 i l = firstn (Z.to_nat i) l.
Proof. unfold_sublist_old. rewrite Zminus_0_r, skipn_0. trivial. Qed.

Lemma sublist_app1:
  forall (A : Type) (k i : Z) (al bl : list A),
  0 <= k <= i -> i <= Zlength al -> sublist k i (al ++ bl) = sublist k i al.
Proof. intros.
  unfold_sublist_old. rewrite skipn_app1. rewrite firstn_app1. trivial.
  rewrite skipn_length, Z2Nat.inj_sub. apply Nat2Z.inj_le.
  repeat rewrite Nat2Z.inj_sub. rewrite Z2Nat.id, <- Zlength_correct. lia. lia.
  rewrite <- ZtoNat_Zlength. apply Z2Nat.inj_le; lia.
  apply Z2Nat.inj_le; lia. lia. rewrite <- ZtoNat_Zlength. apply Z2Nat.inj_le; lia.
Qed.

Lemma sublist0_app1 {A} i (al bl:list A): 0<= i <= Zlength al ->
  sublist 0 i (al ++ bl) = sublist 0 i al.
Proof. intros. apply sublist_app1; lia. Qed.

Lemma sublist_app2 {A} i j (al bl:list A): 0<=Zlength al <= i->
  sublist i j (al ++ bl) = sublist (i-Zlength al) (j-Zlength al) bl.
Proof.
  intros. unfold_sublist_old.
  rewrite skipn_app2.
  repeat rewrite Z2Nat.inj_sub. repeat rewrite ZtoNat_Zlength.
  remember ((Z.to_nat i - length al)%nat) as k.
  rewrite <- Nat.sub_add_distr.
  assert (K: (length al + k = Z.to_nat i)%nat).
    subst k. rewrite <- le_plus_minus. trivial.
    apply Nat2Z.inj_le. rewrite Z2Nat.id. rewrite Zlength_correct in H; apply H. lia.
  rewrite K. trivial.
  lia. lia. lia. lia.
  apply Nat2Z.inj_le. rewrite Z2Nat.id. rewrite Zlength_correct in H; apply H. lia.
Qed.

Lemma sublist_sublist0 {A} i j k (l:list A): 0<=k -> k<=i<=j ->
  sublist k i (sublist 0 j l) = sublist k i l.
Proof. intros. rewrite sublist_sublist; repeat rewrite Zplus_0_r; trivial; lia. Qed.

Lemma sublist_sublist00 {A} i j (l:list A): 0<=i<=j ->
  sublist 0 i (sublist 0 j l) = sublist 0 i l.
Proof. intros. apply sublist_sublist0; lia. Qed.

Lemma skipn_repeat:
   forall A k n (a: A),
     (k <= n)%nat -> skipn k (repeat a n) = repeat a (n-k).
Proof.
 induction k; destruct n; simpl; intros; auto.
 apply IHk; auto. lia.
Qed.

Lemma sublist_repeat {A} i j k (v:A) (I: 0<=i)
          (IJK: i <= j <= k):
      sublist i j (repeat v (Z.to_nat k)) = repeat v (Z.to_nat (j-i)).
Proof.
  unfold_sublist_old.
  rewrite skipn_repeat.
  rewrite firstn_repeat.
  trivial.
  rewrite <- Z2Nat.inj_sub by lia.
  apply Z2Nat.inj_le; lia.
  apply Z2Nat.inj_le; lia.
Qed.

Lemma sublist_Zrepeat {A} i j k (v:A) (I: 0<=i)
          (IJK: i <= j <= k):
      sublist i j (Zrepeat v k) = Zrepeat v (j-i).
Proof.
  apply @sublist_repeat; auto.
Qed.

Lemma repeat_0:
  forall {A} (x:A), repeat x (Z.to_nat 0) = nil.
Proof.
simpl. auto.
Qed.

Lemma Zrepeat_neg: forall {A} (v: A) n, n<=0 -> Zrepeat v n = nil.
Proof.
intros.
unfold Zrepeat.
replace (Z.to_nat n) with O by lia.
reflexivity.
Qed.

Lemma Zrepeat_0:
  forall {A} (x:A), Zrepeat x 0 = nil.
Proof.
simpl. auto.
Qed.

Lemma Znth_repeat_inrange:
  forall {A}{d: Inhabitant A} i n (a: A),
   (0 <= i < n)%Z ->
   Znth i (repeat a (Z.to_nat n)) = a.
Proof.
intros.
unfold Znth; rewrite if_false by lia.
assert (Z.to_nat i < Z.to_nat n)%nat
  by (apply Z2Nat.inj_lt; lia).
forget (Z.to_nat n) as k.
revert k H0; induction (Z.to_nat i); destruct k; simpl; intros.
lia. auto. lia. apply IHn0; lia.
Qed.

Lemma Znth_Zrepeat : forall (A : Type) (d : Inhabitant A) (i n : Z) (x : A),
  0 <= i < n ->
  Znth i (Zrepeat x n) = x.
Proof.  exact @Znth_repeat_inrange. Qed.

Lemma firstn_nil {A} n: firstn n (nil:list A) = nil.
Proof.  destruct n; reflexivity. Qed.

Lemma firstn_In {A} (x:A): forall l n, In x (firstn n l) -> In x l.
Proof.
  induction l; simpl; intros.
  rewrite firstn_nil in H. inv H.
  destruct n; simpl in *. contradiction.
  destruct H; eauto.
Qed.
Lemma skipn_In {A} (x:A): forall l n, In x (skipn n l) -> In x l.
Proof.
  induction l; simpl; intros.
  rewrite skipn_nil in H. inv H.
  destruct n; simpl in *. trivial. right; eauto.
Qed.

Lemma sublist_In {A} lo hi data (x:A) (I:In x (sublist lo hi data)): In x data.
Proof. eapply firstn_In. eapply skipn_In. apply I. Qed.

Lemma Zlength_repeat' {A} n (v:A): Zlength (repeat v n) = Z.of_nat n.
Proof. rewrite Zlength_correct, repeat_length; trivial. Qed.

Lemma sublist0_app2 {A : Type} i (al bl : list A):
  Zlength al <= i <= Zlength al + Zlength bl ->
  sublist 0 i (al ++ bl) = al ++ sublist 0 (i - Zlength al) bl.
Proof. specialize (Zlength_nonneg al); specialize (Zlength_nonneg bl); intros.
rewrite <- (sublist_rejoin 0 (Zlength al) i); try rewrite Zlength_app; try lia.
rewrite sublist0_app1, sublist_same; try lia.
 rewrite sublist_app2, Zminus_diag; trivial. lia.
Qed.


Lemma sublist_rejoin':
  forall {A} lo mid mid' hi (al: list A),
  mid=mid' ->
  0 <= lo <= mid ->
  mid' <= hi <= Zlength al ->
  sublist lo mid al ++ sublist mid' hi al = sublist lo hi al.
Proof.
intros.
subst mid'.
apply sublist_rejoin; auto.
Qed.

#[export] Hint Rewrite @sublist_nil' using old_list_solve: sublist.
#[export] Hint Rewrite @app_nil_l : sublist.
#[export] Hint Rewrite @Zlength_rev : sublist.
#[export] Hint Rewrite @sublist_rejoin' using old_list_solve : sublist.

Lemma subsub1:
 forall a b : Z, (a-(a-b)) = b.
Proof.  intros. lia. Qed.
#[export] Hint Rewrite subsub1 : sublist.

Lemma sublist_app':
  forall {A} lo hi (al bl: list A),
  0 <= lo <= Zlength al ->
  0 <= hi-Zlength al <= Zlength bl ->
  sublist lo hi (al++bl) =
  sublist lo (Zlength al) al ++
  sublist 0 (hi-Zlength al) bl.
Proof.
intros.
unfold_sublist_old.
simpl.
rewrite Zskipn_app1 by lia.
rewrite Zfirstn_app2
 by (rewrite Zlength_skipn, Z.max_r;
      rewrite ?Z.max_r; lia).
rewrite Zlength_skipn, Z.max_r;
      rewrite ?Z.max_r; try lia.
rewrite (Zfirstn_exact_length (Zlength al - lo))
 by (rewrite Zlength_skipn, Z.max_r;
      rewrite ?Z.max_r; lia).
f_equal.
f_equal.
f_equal.
lia.
Qed.

Lemma upd_Znth_Zlength {A} i (l:list A) v: 0<=i < Zlength l ->
      Zlength (upd_Znth i l v) = Zlength l.
Proof. intros.
   unfold_upd_Znth_old. rewrite Zlength_app, Zlength_cons; simpl.
  repeat rewrite Zlength_sublist; simpl; lia.
Qed.

Lemma upd_Znth_map {A B} (f:A -> B) i l v:
      upd_Znth i (map f l) (f v) =
      map f (upd_Znth i l v).
Proof.
  unfold upd_Znth. repeat if_tac; rewrite ?Zlength_map in *; auto; try lia.
  rewrite !map_app. simpl. rewrite !map_sublist. auto.
Qed.

Lemma upd_Znth_lookup K {A}{d: Inhabitant A}: forall l (L:Zlength l = K) i j (v:A) (I: 0<=i<K) (J: 0<=j<K),
   (i=j /\ Znth i (upd_Znth j l v) = v) \/
   (i<>j /\ Znth i (upd_Znth j l v) = Znth i l).
Proof.
  intros. unfold_upd_Znth_old.
  destruct (Z.eq_dec i j); subst.
  + left; split; trivial.
    rewrite app_Znth2; rewrite Zlength_sublist; try rewrite Zminus_0_r; try rewrite Zminus_diag; try lia.
    rewrite Znth_0_cons. trivial.
  + right; split; trivial.
    destruct (Z_lt_dec i j).
    - rewrite app_Znth1; try rewrite Zlength_sublist; try lia.
      rewrite Znth_sublist; try lia. rewrite Zplus_0_r; trivial.
    - rewrite app_Znth2; rewrite Zlength_sublist; try lia.
      rewrite Zminus_0_r, Znth_pos_cons, Znth_sublist; try lia.
      assert (H: i - j - 1 + (j + 1) = i) by lia. rewrite H; trivial.
Qed.

Lemma upd_Znth_lookup' K {A}{d: Inhabitant A}: forall l (L:Zlength l = K) i (I: 0<=i<K) j (J: 0<=j<K) (v:A),
    Znth i (upd_Znth j l v) = if Z.eq_dec i j then v else Znth i l.
Proof. intros.
  destruct (upd_Znth_lookup K l L i j v I J) as [[X Y] | [X Y]]; if_tac; try lia; trivial.
Qed.

Lemma upd_Znth_char {A} n l1 (v:A) l2 w: Zlength l1=n ->
      upd_Znth n (l1 ++ v :: l2) w = l1 ++ w :: l2.
Proof. intros. unfold_upd_Znth_old.
  specialize (Zlength_nonneg l1); intros.
  f_equal. rewrite sublist0_app1. apply sublist_same; lia. lia.
  f_equal. rewrite sublist_app2, <- H, Zlength_app, Zlength_cons. do 2 rewrite Zminus_plus.
                rewrite sublist_1_cons. apply sublist_same; lia. lia.
Qed.

Lemma upd_Znth_same {A}{d: Inhabitant A}: forall i l u, 0<= i< Zlength l -> Znth i (upd_Znth i l u) = u.
Proof.
  intros. rewrite (upd_Znth_lookup' _ _ (eq_refl _)); trivial.
  rewrite if_true; trivial.
Qed.

Lemma upd_Znth_diff {A}{d: Inhabitant A}: forall i j l u, 0<= i< Zlength l -> 0<= j< Zlength l -> i<>j ->
      Znth i (upd_Znth j l u) = Znth i l.
Proof.
  intros. rewrite (upd_Znth_lookup' _ _ (eq_refl _)); trivial.
  rewrite if_false; trivial.
Qed.

Lemma upd_Znth_app1 {A} i l1 l2 (I: 0 <= i < Zlength l1) (v:A):
      upd_Znth i (l1++l2) v = upd_Znth i l1 v ++ l2.
Proof.
  assert (L2NN:= Zlength_nonneg l2).
  unfold_upd_Znth_old.
  rewrite sublist_app1, Zlength_app, <- app_assoc; try lia.
  f_equal. simpl. f_equal.
  rewrite <- (sublist_rejoin (i+1) (Zlength l1)); try lia.
  rewrite sublist_app1; try lia. f_equal.
  rewrite sublist_app2, Zminus_diag, Zminus_plus; try lia.
  apply sublist_same; trivial.
  rewrite Zlength_app; lia.
Qed.

Lemma upd_Znth_app2 {A} (l1 l2:list A) i v:
  Zlength l1 <= i <= Zlength l1 + Zlength l2 ->
  upd_Znth i (l1 ++ l2) v = l1 ++ upd_Znth (i-Zlength l1) l2 v.
Proof. intros.
  destruct (Z_lt_dec i (Zlength l1 + Zlength l2)).
  - unfold_upd_Znth_old.
    rewrite sublist0_app2; trivial. rewrite <- app_assoc. f_equal. f_equal. f_equal.
    rewrite sublist_app2, Zlength_app, Zminus_plus.
    assert (i + 1 - Zlength l1 = i - Zlength l1 + 1) by lia. rewrite H0; trivial.
    specialize (Zlength_nonneg l1); lia.
  - unfold upd_Znth. repeat if_tac; rewrite ?Zlength_app in *; try lia.
    auto.
Qed.

Lemma upd_Znth0_old {A} (l:list A) v:
  Zlength l > 0 ->
  upd_Znth 0 l v = v :: sublist 1 (Zlength l) l.
Proof. intros. unfold_upd_Znth_old. rewrite sublist_nil. reflexivity. Qed.

Lemma upd_Znth0 : forall {A} x (l : list A) y,
  upd_Znth 0 (x :: l) y = y :: l.
Proof.
  intros.
  unfold upd_Znth. if_tac.
  - simpl. rewrite sublist_1_cons.
    rewrite sublist_same; auto.
    rewrite Zlength_cons. lia.
  - rewrite Zlength_cons in H.
    pose proof (Zlength_nonneg l).
    lia.
Qed.

Lemma sublist_upd_Znth_l: forall {A} (l: list A) i lo hi v,
  0 <= lo <= hi ->
  hi <= i < Zlength l ->
  sublist lo hi (upd_Znth i l v) = sublist lo hi l.
Proof.
  intros.
  unfold_upd_Znth_old.
  rewrite sublist_app1.
  2: lia.
  2: rewrite Zlength_sublist by lia; lia.
  rewrite sublist_sublist by lia.
  f_equal; lia.
Qed.

Lemma sublist_upd_Znth_r: forall {A} (l: list A) i lo hi v,
  0 <= i < lo ->
  lo <= hi <= Zlength l ->
  sublist lo hi (upd_Znth i l v) = sublist lo hi l.
Proof.
  intros.
  unfold_upd_Znth_old.
  replace (sublist 0 i l ++ v :: sublist (i + 1) (Zlength l) l) with
    ((sublist 0 i l ++ v :: nil) ++ sublist (i + 1) (Zlength l) l)
    by (rewrite <- app_assoc; auto).
  rewrite sublist_app2.
  2: rewrite Zlength_app, Zlength_sublist, Zlength_correct by lia; simpl; lia.
  rewrite Zlength_app, Zlength_sublist, Zlength_correct by lia; simpl.
  rewrite sublist_sublist by lia.
  f_equal; lia.
Qed.

Lemma sublist_upd_Znth_lr: forall {A} (l: list A) i lo hi v,
  0 <= lo <= i->
  i < hi <= Zlength l ->
  sublist lo hi (upd_Znth i l v) = upd_Znth (i - lo) (sublist lo hi l) v.
Proof.
  intros.
  unfold_upd_Znth_old.
  rewrite upd_Znth_old_upd_Znth. 2 : {
    rewrite Zlength_sublist by lia.
    lia.
  }
  unfold old_upd_Znth.
  change (v :: sublist (i + 1) (Zlength l) l) with
    ((v :: nil) ++ sublist (i + 1) (Zlength l) l).
  rewrite !sublist_app'.
  2: change (Zlength [v]) with 1; lia.
  2: change (Zlength [v]) with 1; rewrite !Zlength_sublist by lia; lia.
  2: rewrite !Zlength_sublist by lia; lia.
  2: rewrite Zlength_app, !Zlength_sublist by lia; change (Zlength [v]) with 1; lia.
  rewrite !Zlength_sublist by lia.
  change (Zlength [v]) with 1.
  rewrite (@sublist_len_1 _ v) by (change (Zlength [v]) with 1; lia).
  change (@Znth _ v 0 [v]) with v.
  simpl.
  rewrite !sublist_sublist by lia.
  f_equal; [| f_equal]; f_equal; lia.
Qed.

#[export] Hint Rewrite @Znth_Zrepeat using lia : sublist.
#[export] Hint Rewrite @Znth_repeat_inrange using lia : sublist.
#[export] Hint Rewrite @Zlength_cons @Zlength_nil: sublist.
#[export] Hint Rewrite @Zrepeat_neg using lia : sublist.
#[export] Hint Rewrite @repeat_0 @Zrepeat_0: sublist.
#[export] Hint Rewrite <- @app_nil_end : sublist.
#[export] Hint Rewrite @Zlength_app: sublist.
#[export] Hint Rewrite @Zlength_map: sublist.
#[export] Hint Rewrite @Zlength_Zrepeat using old_list_solve: sublist.
#[export] Hint Rewrite @Zlength_repeat using old_list_solve: sublist.
#[export] Hint Rewrite Z.sub_0_r Z.add_0_l Z.add_0_r : sublist.
#[export] Hint Rewrite @Zlength_sublist using old_list_solve: sublist.
#[export] Hint Rewrite Z.max_r Z.max_l using lia : sublist.
#[export] Hint Rewrite Z.min_r Z.min_l using lia : sublist.
#[export] Hint Rewrite Z.add_simpl_r Z.sub_add Z.sub_diag : sublist.
#[export] Hint Rewrite @sublist_sublist using old_list_solve : sublist.
#[export] Hint Rewrite @sublist_app1 using old_list_solve : sublist.
#[export] Hint Rewrite @sublist_app2 using old_list_solve : sublist.
#[export] Hint Rewrite @sublist_repeat @sublist_Zrepeat using old_list_solve : sublist.
#[export] Hint Rewrite @sublist_same using old_list_solve : sublist.
#[export] Hint Rewrite Z.add_simpl_l : sublist.
#[export] Hint Rewrite Z.add_add_simpl_l_l Z.add_add_simpl_l_r
     Z.add_add_simpl_r_l Z.add_add_simpl_r_r : sublist.
#[export] Hint Rewrite Z.add_0_r : sublist.
#[export] Hint Rewrite @app_Znth1 using old_list_solve : sublist.
#[export] Hint Rewrite @app_Znth2 using old_list_solve : sublist.
#[export] Hint Rewrite @Znth_sublist using old_list_solve : sublist.
#[export] Hint Rewrite @upd_Znth_Zlength using old_list_solve : sublist.


#[export] Hint Rewrite @sublist_nil : sublist.

Lemma repeat_app  (* duplicate this from Coq standard library
     for compatibility with Coq 8.12, where it is not present *)
  : forall {A: Type} (x: A) (n m: nat),
         repeat x (n + m) = repeat x n ++ repeat x m.
Proof.
intros.
induction n; simpl; auto.
f_equal; auto.
Qed.

Lemma repeat_app':
 forall {A: Type} a b (x:A), 
    0 <= a -> 0 <= b ->
    repeat x (Z.to_nat a) ++ repeat x (Z.to_nat b) = repeat x (Z.to_nat (a+b)).
Proof.
 intros.
 rewrite <- repeat_app. f_equal.
  apply Nat2Z.inj. rewrite <- Z2Nat.inj_add; auto.
Qed.

Lemma Zrepeat_app:
 forall {A: Type} (a b: Z) (x:A), 
    0 <= a -> 0 <= b ->
    Zrepeat x a ++ Zrepeat x b = Zrepeat x (a+b).
Proof.
  exact @repeat_app'.
Qed.

Lemma Znth_overflow:
  forall {A}{d: Inhabitant A} i (al: list A), i >= Zlength al -> Znth i al = d.
Proof.
intros.
  pose proof (Zlength_nonneg al).
   unfold Znth. rewrite if_false by lia.
  apply nth_overflow.
  apply Nat2Z.inj_le. rewrite <- Zlength_correct.
  rewrite Z2Nat.id by lia. lia.
Qed.

Lemma Znth_underflow:
  forall {A}{d: Inhabitant A} i (al: list A),  i < 0 -> Znth i al = d.
Proof.
intros.
   unfold Znth. rewrite if_true by lia. auto.
Qed.

Lemma Znth_outofbounds:
  forall {A}{d: Inhabitant A} i (al: list A),  (i < 0 \/ i >= Zlength al) -> Znth i al = d.
Proof.
intros.
  destruct H. apply Znth_underflow; auto. apply Znth_overflow; auto.
Qed.

Lemma sublist_one:
  forall {A}{d: Inhabitant A} lo hi (al: list A),
    0 <= lo -> hi <= Zlength al ->
    lo+1=hi -> sublist lo hi al = Znth lo al :: nil.
Proof.
intros.
subst.
rewrite Znth_cons_sublist by lia. rewrite <- app_nil_end.
auto.
Qed.

Lemma Forall_app :
forall {A} P (l1 l2 :list A),
Forall P (l1 ++ l2) <->
Forall P l1 /\ Forall P l2.
intros.
split; induction l1; intros.
inv H. destruct l2; inv H0. auto.
split. auto. simpl in H2. inv H2.
constructor; auto.
split. inv H. constructor; auto. apply IHl1 in H3.
intuition.
inv H. apply IHl1 in H3. intuition.
simpl. intuition.
simpl. constructor.
destruct H. inv H. auto.
apply IHl1. intuition.
inv H0; auto.
Qed.

Lemma Forall_firstn:
  forall A (f: A -> Prop) n l, Forall f l -> Forall f (firstn n l).
Proof.
induction n; destruct l; intros.
constructor. constructor. constructor.
inv H. simpl. constructor; auto.
Qed.

Lemma Forall_skipn:
  forall A (f: A -> Prop) n l, Forall f l -> Forall f (skipn n l).
Proof.
induction n; destruct l; intros.
constructor. inv H; constructor; auto. constructor.
inv H. simpl.  auto.
Qed.

Lemma Forall_map:
  forall {A B} (f: B -> Prop) (g: A -> B) al,
   Forall f (map g al) <-> Forall (Basics.compose f g) al.
Proof.
intros.
induction al; simpl; intuition; inv H1; constructor; intuition.
Qed.

Lemma Forall_sublist:
  forall {A} (f: A -> Prop) lo hi al,
   Forall f al -> Forall f (sublist lo hi al).
Proof.
intros.
apply Forall_skipn. apply Forall_firstn. auto.
Qed.

#[export] Hint Rewrite @upd_Znth_app1 using old_list_solve : sublist.
#[export] Hint Rewrite @upd_Znth_app2 using old_list_solve : sublist.

Lemma map_repeat: forall {A B} (f: A->B) n (x:A), map f (repeat x n) = repeat (f x) n.
Proof.
intros. induction n; simpl; f_equal; auto.
Qed.

Lemma map_Zrepeat: forall {A B} (f: A->B) n (x:A), 
    map f (Zrepeat x n) = Zrepeat (f x) n.
Proof.
intros.
apply map_repeat.
Qed.

#[export] Hint Rewrite @map_repeat @map_Zrepeat: sublist.

Lemma Zlength_sublist_correct: forall {A} (l: list A) (lo hi: Z),
  0 <= lo <= hi ->
  hi <= Zlength l ->
  Zlength (sublist lo hi l) = hi - lo.
Proof.
  intros.
  unfold_sublist_old.
  rewrite Zlength_firstn.
  rewrite Z.max_r by lia.
  rewrite Z.min_l; auto.
  rewrite Zlength_skipn.
  rewrite (Z.max_r 0 lo) by lia.
  rewrite Z.max_r by lia.
  lia.
Qed.

Lemma Zlength_sublist_incorrect: forall {A} (l: list A) (lo hi: Z),
  0 <= lo < hi ->
  hi > Zlength l ->
  Zlength (sublist lo hi l) < hi - lo.
Proof.
  intros.
  unfold_sublist_old.
  rewrite Zlength_firstn.
  rewrite Z.max_r by lia.
  assert (Zlength (skipn (Z.to_nat lo) l) < hi - lo); [| rewrite Z.min_r; lia].
  rewrite Zlength_skipn.
  rewrite (Z.max_r 0 lo) by lia.
  apply Z.max_lub_lt; lia.
Qed.

Lemma nth_Znth {A} {d: Inhabitant A}:
forall n (xs:list A), 0 <= n < Zlength xs -> (nth (Z.to_nat n) xs d) = (Znth n xs).
Proof. intros; unfold Znth; if_tac; unfold default. lia. reflexivity. Qed.

Lemma nth_Znth' : forall {A}{d: Inhabitant A} i l, nth i l default = Znth (Z.of_nat i) l.
Proof.
  intros; unfold Znth.
  destruct (Z_lt_dec (Z.of_nat i) 0); [lia|].
  rewrite Nat2Z.id; auto.
Qed.

 Lemma In_Znth : forall {A} {d: Inhabitant A} (l : list A) x,
    In x l ->
    exists i, 0 <= i < Zlength l /\ Znth i l = x.
Proof.
  unfold Znth; intros.
  apply In_nth with (d := d) in H; destruct H as (n & ? & ?).
  exists (Z.of_nat n); split.
  - rewrite Zlength_correct; lia.
  - destruct (Z_lt_dec (Z.of_nat n) 0); [lia|].
    rewrite Nat2Z.id; auto.
Qed.

Lemma In_upd_Znth_old : forall {A}{d: Inhabitant A} i (x y : A) l, In x l -> x <> Znth i l -> 0 <= i <= Zlength l ->
  In x (upd_Znth i l y).
Proof.
  intros.
  apply In_Znth in H; destruct H as (j & ? & ?); subst.
  assert (i <> j) by (intro; now subst). unfold upd_Znth. if_tac.
  - clear H1. apply in_or_app; simpl. destruct (Z_lt_dec j i); [left | right; right].
    + erewrite <- (Z.add_0_r j), <- Znth_sublist;
        [apply Znth_In; rewrite Zlength_sublist| |]; auto; lia.
    + erewrite <- (Z.sub_simpl_r _ (i + 1)), <- Znth_sublist;
        [apply Znth_In; rewrite Zlength_sublist| |]; lia.
  - now apply Znth_In.
Qed.

Lemma Znth_combine : forall {A B} {a: Inhabitant A} {b: Inhabitant B} i (l1: list A) (l2: list B), 
   Zlength l1 = Zlength l2 ->
  Znth i (combine l1 l2) = (Znth i l1, Znth i l2).
Proof.
  intros; unfold Znth.
  destruct (Z_lt_dec i 0); auto.
  apply combine_nth.
  rewrite !Zlength_correct in *; lia.
Qed.

Lemma Zlength_combine : forall {A B} (l : list A) (l' : list B),
  Zlength (combine l l') = Z.min (Zlength l) (Zlength l').
Proof.
  intros; rewrite !Zlength_correct, combine_length, Nat2Z.inj_min; auto.
Qed.

Lemma upd_Znth_cons : forall {A} i a l (x : A), i > 0 ->
  upd_Znth i (a :: l) x = a :: upd_Znth (i - 1) l x.
Proof.
  intros. unfold upd_Znth. autorewrite with sublist.
  assert (Zlength [a] = 1) by now vm_compute.
  if_tac; if_tac; auto; try (exfalso; lia).
  change (a :: l) with ([a] ++ l). rewrite sublist0_app2.
  - simpl. rewrite H0. do 3 f_equal.
    change (Z.succ (Zlength l)) with (Zlength l + 1).
    rewrite <- sublist_sublist with (j := Zlength l + 1) by lia.
    rewrite sublist_1_cons. f_equal. now rewrite sublist_same by lia.
  - rewrite H0. lia.
Qed.

Lemma sublist_next : forall {A}{d: Inhabitant A} i j l,
      0 <= i < j -> j <= Zlength l ->
  sublist i j l = Znth i l :: sublist (i + 1) j l.
Proof.
  intros.
  rewrite Znth_cons_sublist; [|lia].
  apply sublist_split; lia.
Qed.

Lemma upd_Znth_triv : forall {A}{d: Inhabitant A} i (l : list A) x (Hi : 0 <= i < Zlength l),
  Znth i l = x -> upd_Znth i l x = l.
Proof.
  intros; unfold upd_Znth. subst; rewrite <- sublist_next by lia.
  rewrite <- sublist_split by lia. rewrite sublist_same by lia. now if_tac.
Qed.

Lemma combine_upd_Znth : forall {A B} (l1 : list A) (l2 : list B) i x1 x2, 0 <= i < Zlength l1 ->
  Zlength l1 = Zlength l2 -> combine (upd_Znth i l1 x1) (upd_Znth i l2 x2) = upd_Znth i (combine l1 l2) (x1, x2).
Proof.
  induction l1; simpl; intros; [rewrite Zlength_nil in *; lia|].
  destruct l2; [rewrite Zlength_nil in *; lia|].
  rewrite !Zlength_cons in *.
  destruct (Z.eq_dec i 0).
  - subst; rewrite !upd_Znth0. now simpl.
  - rewrite !upd_Znth_cons; try lia; simpl. rewrite IHl1; auto; lia.
Qed.

Corollary combine_upd_Znth1 : forall {A B}{d: Inhabitant B} (l1 : list A) (l2 : list B) i x,
   0 <= i < Zlength l1 ->
  Zlength l1 = Zlength l2 ->
   combine (upd_Znth i l1 x) l2 = upd_Znth i (combine l1 l2) (x, Znth i l2).
Proof.
  intros; rewrite <- combine_upd_Znth by auto.
  erewrite upd_Znth_triv with (l := l2); eauto; lia.
Qed.

Corollary combine_upd_Znth2 : forall {A B}{d: Inhabitant A} (l1 : list A) (l2 : list B) i x, 0 <= i < Zlength l1 ->
  Zlength l1 = Zlength l2 -> combine l1 (upd_Znth i l2 x) = upd_Znth i (combine l1 l2) (Znth i l1, x).
Proof.
  intros; rewrite <- combine_upd_Znth by auto.
  erewrite upd_Znth_triv with (l := l1); eauto; lia.
Qed.

Lemma in_concat : forall {A} (l : list (list A)) x, In x (concat l) <-> exists l1, In x l1 /\ In l1 l.
Proof.
  induction l; simpl; intros.
  - split; [|intros (? & ? & ?)]; contradiction.
  - split; intros.
    + apply in_app_or in H. destruct H; [|rewrite IHl in H]; eauto.
      destruct H as [l1 [? ?]]; eauto.
    + apply in_or_app. destruct H as [l1 [? [? | ?]]]; [subst|]; auto.
      right. rewrite IHl. eauto.
Qed.

Lemma length_concat : forall {A} (l : list (list A)), length (concat l) = fold_right plus O (map (@length A) l).
Proof.
  induction l; auto; simpl.
  rewrite app_length, IHl; auto.
Qed.

Lemma length_concat_min : forall {A}{d: Inhabitant A} (l : list (list A)) i (Hi : 0 <= i < Zlength l),
  (length (Znth i l) <= length (concat l))%nat.
Proof.
  induction l; simpl; intros; [rewrite Zlength_nil in *; lia|].
  rewrite app_length; destruct (Z.eq_dec i 0).
  - subst; rewrite Znth_0_cons; lia.
  - rewrite Znth_pos_cons by lia.
    rewrite Zlength_cons in *; etransitivity; [apply IHl|]; lia.
Qed.

Lemma length_concat_upd : forall {A} {d: Inhabitant A} l i (l' : list A) (Hi : 0 <= i < Zlength l),
  length (concat (upd_Znth i l l')) = (length (concat l) + length l' - length (Znth i l))%nat.
Proof.
  induction l; intros; [rewrite Zlength_nil in *; lia|].
  destruct (Z.eq_dec i 0).
  - subst; rewrite upd_Znth0, Znth_0_cons. simpl. rewrite !app_length. lia.
  - rewrite upd_Znth_cons, Znth_pos_cons by lia; simpl.
    rewrite Zlength_cons in *.
    rewrite !app_length, IHl by lia.
    cut (length (Znth (i - 1) l) <= length (concat l))%nat. lia.
    apply length_concat_min. lia.
Qed.

Lemma incl_nil : forall {A} (l : list A), incl [] l.
Proof.
  repeat intro; contradiction.
Qed.
#[export] Hint Resolve incl_nil : list.

Lemma incl_cons_out : forall {A} (a : A) l1 l2, incl l1 (a :: l2) -> ~In a l1 -> incl l1 l2.
Proof.
  intros; intros ? Hin; specialize (H _ Hin); destruct H; auto; subst; contradiction.
Qed.

Lemma In_upd_Znth : forall {A} i l (x y : A), In x (upd_Znth i l y) -> x = y \/ In x l.
Proof.
  unfold upd_Znth; intros. if_tac in H.
  - apply in_app_or in H; destruct H as [? | [? | ?]]; auto; right;
      eapply sublist_In; eauto.
  - now right.
Qed.

Lemma upd_Znth_In : forall {A} i l (x : A),
    0 <= i < Zlength l -> In x (upd_Znth i l x).
Proof.
  intros; unfold upd_Znth. if_tac.
  - apply in_or_app; simpl; auto.
  - exfalso; lia.
Qed.

Lemma Znth_cons_eq : forall {A}{d : Inhabitant A} i x l, 
   Znth i (x :: l) = if Z.eq_dec i 0 then x else Znth (i - 1) l.
Proof.
  intros.
  destruct (Z.eq_dec i 0); [subst; apply Znth_0_cons|].
  destruct (Z_lt_dec i 0); [rewrite !Znth_underflow; auto; lia|].
  apply Znth_pos_cons; lia.
Qed.

Lemma NoDup_Znth_inj : forall {A} {d : Inhabitant A} l i j (HNoDup : NoDup l)
  (Hi : 0 <= i < Zlength l) (Hj : 0 <= j < Zlength l) (Heq : Znth i l = Znth j l ),
  i = j.
Proof.
  induction l; intros.
  { rewrite Zlength_nil in *; lia. }
  inv HNoDup.
  rewrite Zlength_cons in *.
  rewrite !Znth_cons_eq in Heq.
  destruct (Z.eq_dec i 0), (Z.eq_dec j 0); subst; auto.
  - contradiction H1; apply Znth_In; lia.
  - contradiction H1; apply Znth_In; lia.
  - cut (i - 1 = j - 1). lia. apply IHl; auto; lia.
Qed.

Lemma NoDup_Znth_iff : forall {A}{d: Inhabitant A} (l : list A),
  NoDup l <-> forall i j (Hi : 0 <= i < Zlength l)
                            (Hj : 0 <= j < Zlength l), Znth i l = Znth j l -> i = j.
Proof.
  split; intros; [eapply NoDup_Znth_inj; eauto|].
  induction l; rewrite ?Zlength_cons in *; constructor.
  - intro Hin; eapply In_Znth in Hin; destruct Hin as (j & ? & Hj).
    cut (0 = j + 1). lia. apply H; try lia.
    rewrite !Znth_cons_eq; simpl.
    if_tac; [lia|].
    rewrite Z.add_simpl_r; eauto.
  - apply IHl; intros.
    cut (i + 1 = j + 1). lia. apply H; try lia.
    rewrite !Znth_cons_eq, !Z.add_simpl_r.
    if_tac; [lia|].
    if_tac; [lia | auto].
Qed.

Lemma concat_less_incl : forall {A} l i (l1 l2 : list A) (Hi : 0 <= i < Zlength l)
  (Hless : Znth i l = l1 ++ l2), incl (concat (upd_Znth i l l1)) (concat l).
Proof.
  intros.
  intros ? Hin.
  rewrite in_concat in Hin; rewrite in_concat.
  destruct Hin as (? & ? & Hin).
  apply In_upd_Znth in Hin; destruct Hin; eauto; subst.
  do 2 eexists; [apply in_or_app; left; eauto|].
  rewrite <- Hless; apply Znth_In; auto.
Qed.

Lemma NoDup_app : forall {A} (l1 l2 : list A), NoDup (l1 ++ l2) ->
  NoDup l1 /\ NoDup l2 /\ forall x, In x l1 -> ~In x l2.
Proof.
  induction l1; intros.
  - repeat split; auto; constructor.
  - inv H.
    specialize (IHl1 _ H3); eauto. destruct IHl1 as [? [? ?]].
    repeat split; auto.
    + constructor; auto. intro. apply H2. apply in_or_app. auto.
    + intros ? [? | ?]; auto; subst; auto. intro. apply H2. apply in_or_app; auto.
Qed.

Lemma NoDup_app_iff : forall {A} (l1 l2 : list A), NoDup (l1 ++ l2) <->
  NoDup l1 /\ NoDup l2 /\ forall x, In x l1 -> ~In x l2.
Proof.
  intros; split; [apply NoDup_app|].
  intros (? & ? & Hsep); induction l1; auto.
  inv H; simpl; constructor.
  - rewrite in_app_iff; intros [? | ?]; [contradiction|].
    eapply Hsep; simpl; eauto.
  - apply IHl1; auto.
    intros; apply Hsep; simpl; auto.
Qed.

Corollary NoDup_app_swap : forall {A} (l1 l2 : list A), NoDup (l1 ++ l2) <-> NoDup (l2 ++ l1).
Proof.
  intros; rewrite !NoDup_app_iff; split; intros (? & ? & Hsep); repeat split; auto; repeat intro; eapply Hsep;
    eauto.
Qed.

Lemma NoDup_concat_less : forall {A} l i (l1 l2 : list A) (Hl : NoDup (concat l))
  (Hi : 0 <= i < Zlength l) (Hless : Znth i l = l1 ++ l2),
  NoDup (concat (upd_Znth i l l1)).
Proof.
  induction l; simpl; intros; [rewrite Zlength_nil in *; lia|].
  rewrite Zlength_cons in *.
  destruct (Z.eq_dec i 0).
  - subst; rewrite upd_Znth0. simpl.
    rewrite Znth_0_cons in Hless; subst.
    rewrite <- app_assoc, NoDup_app_swap, <- app_assoc, NoDup_app_iff, NoDup_app_swap in Hl; tauto.
  - rewrite upd_Znth_cons by lia; simpl.
    rewrite Znth_pos_cons in Hless by lia.
    rewrite NoDup_app_iff in Hl; rewrite NoDup_app_iff.
    destruct Hl as (? & ? & Hsep).
    split; [auto|]; split.
    + eapply IHl; eauto; lia.
    + intros ?? Hin; eapply Hsep; eauto.
      eapply concat_less_incl; eauto; lia.
Qed.

Lemma Forall2_Znth : forall {A B}{d1: Inhabitant A}{d2: Inhabitant B} (P : A -> B -> Prop) l1 l2 (Hall : Forall2 P l1 l2) i
  (Hi : 0 <= i < Zlength l1), P (Znth i l1) (Znth i l2).
Proof.
  induction 1; intros.
  { rewrite Zlength_nil in *; lia. }
  rewrite Zlength_cons in *.
  destruct (Z.eq_dec i 0).
  - subst; rewrite !Znth_0_cons; auto.
  - rewrite !Znth_pos_cons; try lia.
    apply IHHall; lia.
Qed.

Lemma Forall2_app_inv : forall {A B} (P : A -> B -> Prop) l1 l2 l3 l4 (Hlen : length l1 = length l3),
  Forall2 P (l1 ++ l2) (l3 ++ l4) -> Forall2 P l1 l3 /\ Forall2 P l2 l4.
Proof.
  induction l1; destruct l3; try discriminate; auto; intros.
  inv H; inv Hlen.
  specialize (IHl1 _ _ _ H0 H5); destruct IHl1 as [? ?]; split; [constructor|]; auto.
Qed.

Lemma Forall2_firstn : forall {A B} (P : A -> B -> Prop) l1 l2 n, Forall2 P l1 l2 ->
  Forall2 P (firstn n l1) (firstn n l2).
Proof.
  intros; revert n; induction H; intro.
  - rewrite !firstn_nil; auto.
  - destruct n; simpl; auto.
Qed.

Lemma Forall2_length {A B} {f:A -> B -> Prop} {l1 l2} (F:Forall2 f l1 l2): length l1 = length l2.
Proof. induction F; trivial. simpl; rewrite IHF. trivial. Qed.

Lemma Forall2_Zlength {A B} {f:A -> B -> Prop} {l1 l2} (F:Forall2 f l1 l2): Zlength l1 = Zlength l2.
Proof. do 2 rewrite Zlength_correct. rewrite (Forall2_length F). trivial. Qed.

Lemma Forall2_upd_Znth : forall {A B} (P : A -> B -> Prop) l1 l2 i x1 x2, Forall2 P l1 l2 ->
  P x1 x2 -> 0 <= i <= Zlength l1 -> Forall2 P (upd_Znth i l1 x1) (upd_Znth i l2 x2).
Proof.
  intros; unfold upd_Znth.
  pose proof (Forall2_Zlength H) as Hlen.
  if_tac; if_tac; auto; try (exfalso; lia).
  erewrite <- sublist_same with (al := l1), sublist_split with (mid := i) in H; auto; try lia.
  erewrite <- sublist_same with (al := l2), sublist_split with (al := l2)(mid := i) in H; auto; try lia.
  apply Forall2_app_inv in H.
  2: now rewrite <- !ZtoNat_Zlength, !Zlength_sublist_correct by lia.
  destruct H as (? & Hall); apply Forall2_app; auto.
  constructor; auto.
  destruct (Z.eq_dec i (Zlength l1)).
  - rewrite !sublist_nil_gen; auto; lia.
  - rewrite Z.add_comm.
    replace (Zlength l1) with (Zlength l1 - i + i) by lia.
    replace (Zlength l2) with (Zlength l2 - i + i) by lia.
    erewrite <- !sublist_sublist with (j := Zlength l1); try lia.
    inversion Hall as [Hl1 Hl2 | ?????? Hl1 Hl2].
    + rewrite !Hlen, <- Hl2.
      unfold sublist; rewrite !firstn_nil, !skipn_nil; auto.
    + rewrite sublist_1_cons, !Hlen, <- Hl2, sublist_1_cons.
      unfold sublist; simpl; apply Forall2_firstn; auto.
Qed.

Lemma Forall2_impl' : forall {A B} (P Q : A -> B -> Prop) l1 l2,
  (forall a b, In a l1 -> In b l2 -> P a b -> Q a b) -> Forall2 P l1 l2 -> Forall2 Q l1 l2.
Proof.
  induction 2; simpl in *; auto.
Qed.

Lemma Forall2_impl : forall {A B} (P Q : A -> B -> Prop), (forall a b, P a b -> Q a b) ->
  forall l1 l2, Forall2 P l1 l2 -> Forall2 Q l1 l2.
Proof.
  induction 2; auto.
Qed.

Lemma map_id_eq : forall {A} (l : list A), map (@id A) l = l.
Proof.
  induction l; auto.
  simpl; apply f_equal; auto.
Qed.

Lemma Forall2_map : forall {A B C D} (P : A -> B -> Prop) (f1 : C -> A) (f2 : D -> B) l1 l2,
  Forall2 P (map f1 l1) (map f2 l2) <-> Forall2 (fun a b => P (f1 a) (f2 b)) l1 l2.
Proof.
  induction l1.
  - split; intro H.
    + destruct l2; auto; inv H.
    + inv H; simpl; auto.
  - split; intro H.
    + destruct l2; inv H.
      rewrite IHl1 in *; constructor; auto.
    + inv H; simpl; constructor; auto.
      rewrite IHl1; auto.
Qed.

Corollary Forall2_map1 : forall {A B C} (P : A -> B -> Prop) (f : C -> A) l1 l2, Forall2 P (map f l1) l2 <->
  Forall2 (fun a b => P (f a) b) l1 l2.
Proof.
  intros; rewrite <- (map_id_eq l2) at 1; apply Forall2_map.
Qed.

Corollary Forall2_map2 : forall {A B C} (P : A -> B -> Prop) (f : C -> B) l1 l2, Forall2 P l1 (map f l2) <->
  Forall2 (fun a b => P a (f b)) l1 l2.
Proof.
  intros; rewrite <- (map_id_eq l1) at 1; apply Forall2_map.
Qed.

Lemma sublist_max_length : forall {A} i j (al : list A), Zlength (sublist i j al) <= Zlength al.
Proof.
  intros; unfold sublist.
  rewrite Zlength_skipn, Zlength_firstn.
  rewrite Z.max_lub_iff. split; [apply Zlength_nonneg | lia].
Qed.

Lemma sublist_of_nil : forall {A} i j, sublist i j (@nil A) = [].
Proof.
  intros; unfold sublist.
  rewrite firstn_nil, skipn_nil; auto.
Qed.

Lemma sublist_0_cons : forall {A} j x (l : list A), j > 0 ->
  sublist 0 j (x :: l) = x :: sublist 0 (j - 1) l.
Proof.
  intros; unfold sublist; simpl.
  destruct (Z.to_nat j) eqn: Hminus.
  - apply Z.gt_lt in H; rewrite Z2Nat.inj_lt in H; lia.
  - simpl; repeat f_equal. lia.
Qed.

Lemma sublist_S_cons : forall {A} i j x (l : list A), i > 0 ->
  sublist i j (x :: l) = sublist (i - 1) (j - 1) l.
Proof.
  intros; unfold sublist; simpl.
  destruct (Z.to_nat j) eqn: Hi; simpl; rewrite !Z2Nat.inj_sub, Hi by lia; simpl.
  - now rewrite !skipn_nil.
  - rewrite Nat.sub_0_r. remember (Z.to_nat i) as m. destruct m. 1: exfalso; lia.
    rewrite skipn_cons. f_equal. lia.
Qed.

Lemma Forall2_sublist : forall {A B} (P : A -> B -> Prop) l1 l2 i j, Forall2 P l1 l2 -> 0 <= i ->
  Forall2 P (sublist i j l1) (sublist i j l2).
Proof.
  intros; revert j; revert dependent i; induction H; intros.
  - rewrite !sublist_of_nil; constructor.
  - destruct (Z_le_dec j i); [rewrite !sublist_nil_gen; auto; constructor|].
    destruct (Z.eq_dec i 0).
    + subst; rewrite !sublist_0_cons by lia.
      constructor; auto.
    + rewrite !sublist_S_cons by lia.
      apply IHForall2; lia.
Qed.

Lemma Forall_last : forall {A} (P : A -> Prop) d l, Forall P l -> P d -> P (last l d).
Proof.
  destruct l; auto.
  cut (a :: l = removelast (a :: l) ++ [last (a :: l) d]).
  - intro Hlast. intros; rewrite Forall_forall in H; apply H.
  rewrite Hlast at 2; apply in_or_app; simpl; auto.
  - apply app_removelast_last. discriminate.
Qed.

Lemma last_map : forall {A B} (f : A -> B) d l, f (last l d) = last (map f l) (f d).
Proof.
  induction l; auto; simpl.
  destruct l; auto.
Qed.

Lemma In_removelast : forall {A} (l : list A) x, In x (removelast l) -> In x l.
Proof.
  induction l; auto; simpl; intros.
  destruct l; auto.
  destruct H; auto.
Qed.

Definition nil_dec {A} (l : list A) : {l = []} + {l <> []}.
Proof.
  destruct l; auto.
  right; discriminate.
Qed.

Lemma Forall2_upd_Znth_l : forall {A B}{d: Inhabitant B} (P : A -> B -> Prop) l1 l2 i x, Forall2 P l1 l2 ->
  P x (Znth i l2) -> 0 <= i < Zlength l1 -> Forall2 P (upd_Znth i l1 x) l2.
Proof.
  intros.
  erewrite <- @upd_Znth_triv with (l := l2)(i := i); eauto.
  apply Forall2_upd_Znth; eauto; lia.
  apply Forall2_Zlength in H; lia.
Qed.

Lemma Forall2_upd_Znth_r : forall {A B}{d: Inhabitant A} (P : A -> B -> Prop) l1 l2 i x, Forall2 P l1 l2 ->
  P (Znth i l1) x -> 0 <= i < Zlength l1 -> Forall2 P l1 (upd_Znth i l2 x).
Proof.
  intros.
  erewrite <- @upd_Znth_triv with (l := l1)(i := i) by (eauto; lia).
  apply Forall2_upd_Znth; eauto.
  apply Forall2_Zlength in H; lia.
Qed.

Lemma Znth_inbounds : forall {A}{d: Inhabitant A} i (l : list A), 
    Znth i l <> default -> 0 <= i < Zlength l.
Proof.
  intros.
  destruct (Z_lt_dec i 0); [contradiction H; apply Znth_underflow; auto|].
  destruct (Z_lt_dec i (Zlength l)); [lia|].
  rewrite Znth_overflow in H; [contradiction H; auto | lia].
Qed.

Lemma upd_Znth_diff' : forall {A}{d: Inhabitant A} i j l (u : A),
    0 <= j < Zlength l -> i <> j ->
  Znth i (upd_Znth j l u) = Znth i l.
Proof.
  intros.
  destruct (Z_lt_dec i 0).
  { rewrite !Znth_underflow; auto. }
  destruct (Z_lt_dec i (Zlength l)).
  apply upd_Znth_diff; auto; lia.
  { rewrite !Znth_overflow; auto.
    rewrite upd_Znth_Zlength; auto. }
Qed.

Lemma list_nth_error_eq : forall {A} (l1 l2 : list A)
  (Heq : forall j, nth_error l1 j = nth_error l2 j), l1 = l2.
Proof.
  induction l1; destruct l2; auto; intros; try (specialize (Heq O); simpl in Heq; discriminate).
  erewrite IHl1.
  - specialize (Heq O); inv Heq; eauto.
  - intro j; specialize (Heq (S j)); auto.
Qed.

Lemma upd_Znth_twice : forall {A} i l (x y : A), 0 <= i < Zlength l ->
  upd_Znth i (upd_Znth i l x) y = upd_Znth i l y.
Proof.
  intros; unfold upd_Znth. if_tac; if_tac in H0; auto; try (exfalso; lia).
  - rewrite !sublist_app; rewrite ?Zlength_app, ?Zlength_cons, ?Zlength_sublist;
      try lia. rewrite 2Z.min_l, 2Z.min_r, 2Z.max_r, 2Z.max_l; try lia.
    rewrite !sublist_nil, app_nil_r; simpl.
    rewrite sublist_S_cons, !sublist_sublist; try lia.
    f_equal; f_equal; [|f_equal]; lia.
  - rewrite Zlength_app, Zlength_cons, !Zlength_sublist_correct in H0 by lia.
    exfalso; lia.
Qed.

Lemma hd_Znth : forall {A}{d: Inhabitant A} (l : list A), hd default l = Znth 0 l.
Proof.
  destruct l; auto.
Qed.

Fixpoint upto n :=
  match n with
  | O => []
  | S n' => 0 :: map Z.succ (upto n')
  end.

Opaque Z.of_nat.

Lemma upto_app : forall n m, upto (n + m) = upto n ++ map (fun i => Z.of_nat n + i) (upto m).
Proof.
  induction n; simpl; intro.
  - rewrite map_id; auto.
  - rewrite IHn, map_app, map_map, Nat2Z.inj_succ; f_equal; f_equal.
    apply map_ext; intro; lia.
Qed.

Lemma upto_length : forall n, length (upto n) = n.
Proof.
  induction n; auto; simpl.
  rewrite map_length, IHn; auto.
Qed.

Corollary Zlength_upto : forall n, Zlength (upto n) = Z.of_nat n.
Proof.
  intro; rewrite Zlength_correct, upto_length; auto.
Qed.

Lemma skipn_cons : forall {A}{d: Inhabitant A} n (l : list A), (length l > n)%nat ->
  skipn n l = Znth (Z.of_nat n) l :: skipn (S n) l.
Proof.
  induction n; intros; simpl; destruct l; simpl in *; try lia; auto. destruct l.
  - simpl in H. inv H. inv H1.
  - rewrite Nat2Z.inj_succ.
    rewrite Znth_pos_cons; [|lia].
    unfold Z.succ; rewrite Z.add_simpl_r.
    erewrite IHn; auto; lia.
Qed.

Lemma Znth_nil : forall `{Inhabitant} n, Znth n [] = default.
Proof.
  intros; unfold Znth.
  if_tac; auto.
  destruct (Z.to_nat n); auto.
Qed.

Lemma Znth_upto : forall d m n, 
  0 <= n < Z.of_nat m -> @Znth _ d n (upto m) = n.
Proof.
  induction m; simpl; intros.
  - rewrite Znth_nil; simpl in *; rewrite Nat2Z.inj_0 in *; lia.
  - destruct (Z.eq_dec n 0).
    + subst; apply Znth_0_cons.
    + rewrite Nat2Z.inj_succ in *.
      rewrite Znth_pos_cons by lia.
      rewrite Znth_map. rewrite IHm. lia. lia.
      rewrite Zlength_upto. lia.
Qed.

Lemma sublist_upto : forall n a b, 0 <= a <= b -> sublist a b (upto n) = map (Z.add a) (upto (Min.min n (Z.to_nat b) - Z.to_nat a)).
Proof.
  induction n; intros.
  - simpl; rewrite sublist_of_nil by lia; auto.
  - simpl.
    destruct (Z.to_nat b) eqn: Hb.
    { apply f_equal with (f := Z.of_nat) in Hb; rewrite Z2Nat.id in Hb by lia; subst.
      change (Z.of_nat O) with 0 in H.
      assert (a = 0) by lia; subst.
      rewrite sublist_nil; auto. }
    destruct (Z_lt_dec 0 b).
    destruct (Z.eq_dec a 0).
    + subst; rewrite sublist_0_cons, sublist_map, IHn by lia; simpl; f_equal.
      rewrite Z2Nat.inj_sub, Hb by lia; simpl.
      rewrite !Nat.sub_0_r, !map_map; auto.
    + rewrite sublist_S_cons, sublist_map, IHn by lia; simpl.
      destruct (Z.to_nat a) eqn: Ha.
      { apply f_equal with (f := Z.of_nat) in Ha; rewrite Z2Nat.id in Ha by lia; contradiction. }
      rewrite !Z2Nat.inj_sub, Ha, Hb by lia; simpl.
      rewrite !Nat.sub_0_r, !map_map; apply map_ext; intros; lia.
    + destruct (Z.eq_dec b 0); try lia.
Qed.

Transparent Z.of_nat.

Lemma In_upto : forall n i, In i (upto n) <-> 0 <= i < Z.of_nat n.
Proof.
  induction n; intro.
  - simpl; split; try contradiction; lia.
  - rewrite Nat2Z.inj_succ; simpl.
    rewrite in_map_iff; split.
    + intros [? | ?]; [lia|].
      destruct H as (? & ? & ?); subst; rewrite IHn in *; lia.
    + intro; destruct (Z.eq_dec i 0); [auto | right].
      exists (i - 1); rewrite IHn; lia.
Qed.

Lemma Forall2_eq_upto : forall {A B}{d1: Inhabitant A}{d2: Inhabitant B} (P : A -> B -> Prop) l1 l2, Forall2 P l1 l2 <->
  Zlength l1 = Zlength l2 /\ Forall (fun i => P (Znth i l1) (Znth i l2)) (upto (Z.to_nat (Zlength l1))).
Proof.
  induction l1; destruct l2; rewrite ?Zlength_cons, ?Zlength_nil; try solve [split; intro H; inv H;
    try (rewrite Zlength_correct in *; lia)]; simpl.
  - change (upto 0) with (@nil Z); split; auto.
  - rewrite Z2Nat.inj_succ by (apply Zlength_nonneg).
    rewrite <- Nat.add_1_l, upto_app, Forall_app, Forall_map.
    change (upto 1) with [0]; split; intro H.
    + inversion H as [|????? Hall]; subst.
      rewrite IHl1 in Hall; destruct Hall as (? & Hall).
      split; [congruence|].
      split; auto.
      rewrite Forall_forall in *; intros ? Hin.
      unfold Basics.compose.
      specialize (Hall _ Hin).
      rewrite In_upto in Hin.
      rewrite !Znth_pos_cons, Z.add_simpl_l by (simpl Z.of_nat; lia); auto.
    + destruct H as (? & Ha & Hall); inversion Ha as [|?? HP]; subst.
      rewrite !Znth_0_cons in HP.
      constructor; auto.
      rewrite IHl1; split; [lia|].
      rewrite Forall_forall in *; intros ? Hin.
      specialize (Hall _ Hin).
      rewrite In_upto in Hin; unfold Basics.compose in Hall.
      rewrite !Znth_pos_cons, Z.add_simpl_l in Hall by (simpl Z.of_nat; lia); auto.
Qed.

Lemma Forall2_forall_Znth : forall {A B}{d1: Inhabitant A}{d2: Inhabitant B}  (P : A -> B -> Prop) l1 l2,
  Forall2 P l1 l2 <->
  Zlength l1 = Zlength l2 /\ (forall i, 0 <= i < Zlength l1 -> P (Znth i l1) (Znth i l2)).
Proof.
  intros; rewrite Forall2_eq_upto, Forall_forall.
  setoid_rewrite In_upto.
  rewrite Z2Nat.id by (apply Zlength_nonneg).
  reflexivity.
Qed.
