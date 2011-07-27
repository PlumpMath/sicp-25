
(defvar C (make-connector))
(defvar F (make-connector))
(celsius-fahrenheit-converter C F)

(defun celsius-fahrenheit-converter (c f)
  (let ((u (make-connector))
        (v (make-connector))
        (w (make-connector))
        (x (make-connector))
        (y (make-connector)))
    (multiplier c w u)
    (multiplier v x u)
    (adder v y f)
    (constant 9 w)
    (constant 5 x)
    (constant 32 y)
    'ok))

(probe "Celsius temp" C)
(probe "Fahrenheit temp" F)

(set-value! C 25 'user)

(forget-value! C 'user)
(set-value! F 212 'user)

(defun adder (a1 a2 sum)
  (labels ((process-new-value ()
             (cond ((and (has-value? a1) (has-value? a2))
                    (set-value! sum
                                (+ (get-value a1) (get-value a2))
                                #'me))
                   ((and (has-value? a1) (has-valule? sum))
                    (set-value! a2
                                (- (get-value sum) (get-value a1))
                                #'me))
                   ((and (has-value? a2) (has-value? sum))
                    (set-value! a1
                                (- (get-value sum) (get-value a2))
                                #'me))))
           (process-forget-value ()
             (forget-value! sum #'me)
             (forget-value! a1 #'me)
             (forget-value! a2 #'me)
             (process-new-value))
           (me (request)
             (cond
               ((eq request 'I-have-a-value)
                (process-new-value))
               ((eq request 'I-lost-my-value)
                (process-forget-value))
               (t (error "Unknown request -- Adder")))))
    (connect a1 #'me)
    (connect a2 #'me)
    (connect sum #'me)
    #'me))

(defun inform-about-value (constraint)
  (funcall constraint 'I-have-a-value))
(defun inform-about-no-value (constraint)
  (funcall constraint 'I-lost-my-value))

(defun multiplier (m1 m2 product)
  (labels ((process-new-value ()
             (cond
               ((or (and (has-value? m1) (zerop (get-value m1)))
                    (and (has-value? m2) (zerop (get-value m2))))
                (set-value! product
                            0
                            #'me))
               ((and (has-value? m1) (has-value? m2))
                (set-value! product
                            (* (get-value m1) (get-value m2))
                            #'me))
               ((and (has-value? m1) (has-value? product))
                (set-value! m2
                            (/ (get-value product) (get-value m1))
                            #'me))
               ((and (has-value? m2) (has-value? product))
                (set-value! m1
                            (/ (get-value product) (get-value m2))
                            #'me))))
           (process-forget-value ()
             (forget-value! product #'me)
             (forget-value! m1 #'me)
             (forget-value! m2 #'me)
             (process-new-value))
           (me (request)
             (cond
               ((eq request 'I-have-a-value)
                (process-new-value))
               ((eq request 'I-lost-my-value)
                (process-forget-value))
               (t (error "Unknown request -- multiplier")))))
    (connect m1 #'me)
    (connect m2 #'me)
    (connect product #'me)
    #'me))

(defun constant (value connector)
  (labels ((me (request)
             (error "Unknown request -- constant")))
    (connect connector #'me)
    (set-value! connector value #'me)
    #'me))

(defun probe (name connector)
  (labels ((print-probe (value)
             (format t "Probe: ~a = ~a" name value))
           (process-new-value ()
             (print-probe (get-value connector)))
           (process-forget-value ()
             (print-probe "?"))
           (me (request)
             (cond ((eq request 'I-have-a-value)
                    (process-new-value))
                   ((eq request 'I-lost-my-value)
                    (process-forget-value))
                   (t (error "Unknown request -- probe")))))
    (connect connector #'me)
    #'me))

(defun make-connector ()
  (let ((value nil)
        (informat nil)
        (constraints '()))
    (labels
        ((set-my-value! (newval setter)
           (cond
             ((not (has-value? #'me))
              (setf value newval)
              (setf informant setter)
              (for-each-except setter
                               #'inform-about-value
                               constraints))
             ((not (= value newval))
              (error "Contradiction"))
             (t 'ignored)))
         (forget-my-value (retractor)
           (if (eq retractor informant)
               (progn (setf informant false)
                      (for-each-except retractor
                                       #'inform-about-no-value
                                       constraints))
               'ignored))
         (connect (new-constraint)
           (if (not (member new-constraint constraints))
               (push new-constraint constraints))
           (if (has-value? #'me)
               (inform-about-value new-constraint))
           'done)
         (me (request)
           (cond ((eq? 'has-value?)
                  (if informant t nil))
                 ((eq request 'value) value)
                 ((eq request 'set-value!) #'set-my-value)
                 ((eq request 'forget) #'forget-my-value)
                 ((eq request 'connect) #'connect)
                 (t (error "Unknown operation -- Connector")))))
      #'me)))

(defun for-each-except (exception procedure list)
  (mapcar (lambda (item) (funcall procedure item)) (remove exception list)))

(defun has-value? (connector)
  (funcall connector 'has-value?))
(defun get-value (connector)
  (funcall connector 'value))
(defun set-value! (connector new-value informant)
  (funcall (funcall connector 'set-value!) new-value informant))
(defun forget-value! (connector retractor)
  (funcall (funcall connector 'forget) retractor))
(defun connect (connector new-constraint)
  (funcall (funcall connector 'connect) new-constraint))