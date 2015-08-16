namespace MaintenanceRequestLibrary.ui
{
    partial class UI
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.runJobBtn = new System.Windows.Forms.Button();
            this.button2 = new System.Windows.Forms.Button();
            this.logBox = new System.Windows.Forms.ListBox();
            this.SuspendLayout();
            // 
            // runJobBtn
            // 
            this.runJobBtn.Location = new System.Drawing.Point(46, 102);
            this.runJobBtn.Name = "runJobBtn";
            this.runJobBtn.Size = new System.Drawing.Size(159, 23);
            this.runJobBtn.TabIndex = 0;
            this.runJobBtn.Text = "Run MR Jobs";
            this.runJobBtn.UseVisualStyleBackColor = true;
            this.runJobBtn.Click += new System.EventHandler(this.runJobBtn_Click);
            // 
            // button2
            // 
            this.button2.Location = new System.Drawing.Point(46, 64);
            this.button2.Name = "button2";
            this.button2.Size = new System.Drawing.Size(159, 23);
            this.button2.TabIndex = 1;
            this.button2.Text = "Setup MR Simulator";
            this.button2.UseVisualStyleBackColor = true;
            // 
            // logBox
            // 
            this.logBox.FormattingEnabled = true;
            this.logBox.ItemHeight = 16;
            this.logBox.Location = new System.Drawing.Point(46, 179);
            this.logBox.Name = "logBox";
            this.logBox.Size = new System.Drawing.Size(491, 500);
            this.logBox.TabIndex = 2;
            // 
            // UI
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(581, 701);
            this.Controls.Add(this.logBox);
            this.Controls.Add(this.button2);
            this.Controls.Add(this.runJobBtn);
            this.Name = "UI";
            this.Text = "UI";
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button runJobBtn;
        private System.Windows.Forms.Button button2;
        private System.Windows.Forms.ListBox logBox;
    }
}