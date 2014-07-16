using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace ThreadWaiting
{

  public  class WaitingThread
  {
      #region private fields
      private Thread _thrd;
      private Form _waitFrm;
      #endregion

      private string _error;
      /// <summary>
      ///  错误信息
      /// </summary>
      public string Error
      {
          get { return _error; }
          set { _error = value; }
      }

      Action<object> _doEvent;
      public Action<object> DoEvent
      {
          get { return _doEvent; }
          set { _doEvent = value; }
      }

      public WaitingThread (Form waitform)
      {
          _thrd = new Thread(new ParameterizedThreadStart(StartDo));
          _waitFrm = waitform;
      }

      /// <summary>
      /// 线程需要工作内容
      /// </summary>
      /// <param name="para"></param>
      private void StartDo(object para)
      { 
          _doEvent(para);      

          //直到创建句柄
          while (!_waitFrm.IsHandleCreated)
          {
              
          }

          _waitFrm.BeginInvoke(new MethodInvoker(delegate()
          {
              _waitFrm.Close();
              _waitFrm.Dispose();
          }));

      }

      /// <summary>
      /// 启动waitThre工作
      /// </summary>
      /// <param name="para"></param>
      public void ThreadStart(object para)
      {
          try
          {
              _thrd.Start(para);
          }
          catch (Exception e)
          {
              _error = e.Message;             
          }

           if (!_waitFrm.IsDisposed)
          {
              _waitFrm.ShowDialog();
          }
      }
    }
}
