/* >​< >‌‌‌<
 * Developed by R. E. Bryant, 2017
 * Extended to store strings, 2018
 */

/*
 * This program implements a queue supporting both FIFO and LIFO
 * operations.
 *
 * It uses a singly-linked list to represent the set of queue elements
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "harness.h"
#include "queue.h"

/*
  Create empty queue.
  Return NULL if could not allocate space.
*/
queue_t *q_new()
{
    queue_t *q =  malloc(sizeof(queue_t));
    /* What if malloc returned NULL? */
    if(q == NULL) {
      return NULL;
    }
    q->head = NULL;
    q->queueSize = 0;
    q->tail = NULL;

    return q;
}

/* Free all storage used by queue */
void q_free(queue_t *q)
{
    /* How about freeing the list elements and the strings? */
    /* Free queue structure */
    if(q == NULL) {
        return;
    }
    list_ele_t *curNode = q->head;
    list_ele_t *next;
    while(curNode != NULL) {
        next = curNode->next;
        free(curNode->value);
        free(curNode);
        curNode = next;
    }
    free(q);
}

/*
  Attempt to insert element at head of queue.
  Return true if successful.
  Return false if q is NULL or could not allocate space.
  Argument s points to the string to be stored.
  The function must explicitly allocate space and copy the string into it.
 */
bool q_insert_head(queue_t *q, char *s)
{
  if(q == NULL) {
      return false;
    }
    list_ele_t *newh;
    /* What should you do if the q is NULL? */
    newh = malloc(sizeof(list_ele_t));

    if(newh == NULL) {
      return false;
    }
  
    newh->value = malloc(strlen(s) + 1);
    if(newh->value == NULL) {
      free(newh);
      return false;
    }
    newh->value = strcpy(newh->value, s);
    /* Don't forget to allocate space for the string and copy it */
    /* What if either call to malloc returns NULL? */
    /* You must do the cleanup of anything left behind */
    
 

    if(q->queueSize == 0) {
      q->head = newh;
      newh->next = NULL;
      q->tail = newh;
    }
    else if(q->queueSize > 0) {
      newh->next = q->head;
      q->head = newh;
    }
    q->queueSize++;
    
    return true;
}


/*
  Attempt to insert element at tail of queue.
  Return true if successful.
  Return false if q is NULL or could not allocate space.
  Argument s points to the string to be stored.
  The function must explicitly allocate space and copy the string into it.
 */
bool q_insert_tail(queue_t *q, char *s)
{
    if(q == NULL) {
      return false;
    }
    list_ele_t *newh;
    /* What should you do if the q is NULL? */
    newh = malloc(sizeof(list_ele_t));

    if(newh == NULL) {
      return false;
    }
  
    newh->value = malloc(strlen(s) + 1);
    if(newh->value == NULL) {
      free(newh);
      return false;
    }
    newh->value = strcpy(newh->value, s);
    /* You need to write the complete code for this function */
    /* Remember: It should operate in O(1) time */

    

    if(q->queueSize == 0) {

      q->head = newh;
      q->tail = newh;
      newh->next = NULL;
    }
    else if(q->queueSize > 0) {
      q->tail->next = newh;
      q->tail = newh;
      newh->next = NULL;
    }
    q->queueSize++;

    return true;
}

/*
  Attempt to remove element from head of queue.
  Return true if successful.
  Return false if queue is NULL or empty.
  If sp is non-NULL and an element is removed, copy the removed string to *sp
  (up to a maximum of bufsize-1 characters, plus a null terminator.)
  The space used by the list element and the string should be freed.
*/
bool q_remove_head(queue_t *q, char *sp, size_t bufsize)
{
    list_ele_t *newh;

    if(q == NULL || q->queueSize == 0) {
      return false;
    }
    if(sp == NULL) {
      return false;
    }
    /* You need to fix up this code. */
    strncpy(sp,q->head->value, bufsize-1);
    sp[bufsize-1] = '\0';
    newh = q->head;
    q->head = q->head->next;
    free(newh->value);
    free(newh);
    q->queueSize--;
    return true;
}

/*
  Return number of elements in queue.
  Return 0 if q is NULL or empty
 */
int q_size(queue_t *q)
{
    /* You need to write the code for this function */
    /* Remember: It should operate in O(1) time */

    if(q == NULL) {
      return 0;
    }
    return q->queueSize;
}

/*
  Reverse elements in queue
  No effect if q is NULL or empty
  This function should not allocate or free any list elements
  (e.g., by calling q_insert_head, q_insert_tail, or q_remove_head).
  It should rearrange the existing ones.
 */
void q_reverse(queue_t *q)
{
    /* You need to write the code for this function */

    if (q == NULL || q->queueSize == 0) {
      return;
    }

    list_ele_t *prev = NULL;
    list_ele_t *cur = q->head;
    list_ele_t *next = NULL;

    q->tail = q->head;

    while(cur != NULL) {
      next = cur -> next;
      cur->next = prev;
      prev = cur;
      cur = next; 
    }
    q->head = prev;
}

