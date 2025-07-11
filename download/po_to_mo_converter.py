import os
import gettext
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext

class POtoMOConverter:
    def __init__(self, root):
        self.root = root
        self.root.title("PO 到 MO 文件转换器")
        self.root.geometry("650x550")
        
        # 创建主框架
        self.main_frame = tk.Frame(self.root, padx=10, pady=10)
        self.main_frame.pack(fill=tk.BOTH, expand=True)
        
        # 文件选择部分
        self.file_frame = tk.LabelFrame(self.main_frame, text="文件操作", padx=5, pady=5)
        self.file_frame.pack(fill=tk.X, pady=5)
        
        self.btn_open = tk.Button(self.file_frame, text="打开PO文件", command=self.open_po_file)
        self.btn_open.pack(side=tk.LEFT, padx=5)
        
        self.btn_save = tk.Button(self.file_frame, text="保存为MO文件", command=self.save_mo_file)
        self.btn_save.pack(side=tk.LEFT, padx=5)
        
        self.btn_convert = tk.Button(self.file_frame, text="转换", command=self.convert_file)
        self.btn_convert.pack(side=tk.LEFT, padx=5)
        
        # PO文件路径部分
        self.po_frame = tk.Frame(self.main_frame)
        self.po_frame.pack(fill=tk.X, pady=5)
        
        self.lbl_po = tk.Label(self.po_frame, text="PO文件:")
        self.lbl_po.pack(side=tk.LEFT)
        
        self.po_path = tk.StringVar()
        self.entry_po = tk.Entry(self.po_frame, textvariable=self.po_path, width=50)
        self.entry_po.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))
        
        self.btn_browse_po = tk.Button(self.po_frame, text="浏览...", command=self.browse_po_file)
        self.btn_browse_po.pack(side=tk.LEFT)
        
        # MO文件路径部分
        self.mo_frame = tk.Frame(self.main_frame)
        self.mo_frame.pack(fill=tk.X, pady=5)
        
        self.lbl_mo = tk.Label(self.mo_frame, text="MO文件:")
        self.lbl_mo.pack(side=tk.LEFT)
        
        self.mo_path = tk.StringVar()
        self.entry_mo = tk.Entry(self.mo_frame, textvariable=self.mo_path, width=50)
        self.entry_mo.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))
        
        self.btn_browse_mo = tk.Button(self.mo_frame, text="浏览...", command=self.browse_mo_file)
        self.btn_browse_mo.pack(side=tk.LEFT)
        
        # 文件编辑区域
        self.edit_frame = tk.LabelFrame(self.main_frame, text="编辑PO文件内容", padx=5, pady=5)
        self.edit_frame.pack(fill=tk.BOTH, expand=True)
        
        self.text_editor = scrolledtext.ScrolledText(self.edit_frame, wrap=tk.WORD)
        self.text_editor.pack(fill=tk.BOTH, expand=True)
        
        # 初始化变量
        self.current_file = None
    
    def browse_po_file(self):
        """浏览选择PO文件"""
        file_path = filedialog.askopenfilename(
            title="选择PO文件",
            filetypes=[("PO文件", "*.po"), ("所有文件", "*.*")]
        )
        
        if file_path:
            self.po_path.set(file_path)
            self.current_file = file_path
            
            # 自动设置MO文件路径
            mo_path = os.path.splitext(file_path)[0] + ".mo"
            self.mo_path.set(mo_path)
            
            # 读取文件内容
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                self.text_editor.delete(1.0, tk.END)
                self.text_editor.insert(tk.END, content)
    
    def browse_mo_file(self):
        """浏览选择MO文件保存位置"""
        initial_path = self.mo_path.get() if self.mo_path.get() else ""
        file_path = filedialog.asksaveasfilename(
            title="选择MO文件保存位置",
            initialfile=os.path.basename(initial_path),
            defaultextension=".mo",
            filetypes=[("MO文件", "*.mo"), ("所有文件", "*.*")]
        )
        
        if file_path:
            self.mo_path.set(file_path)
    
    def open_po_file(self):
        """打开PO文件(兼容旧方法)"""
        self.browse_po_file()
    
    def save_mo_file(self):
        """保存MO文件"""
        if not self.mo_path.get():
            messagebox.showwarning("警告", "请先指定MO文件路径")
            return
        
        try:
            # 先保存当前编辑的PO内容
            if self.current_file:
                with open(self.current_file, 'w', encoding='utf-8') as f:
                    f.write(self.text_editor.get(1.0, tk.END))
            
            # 转换PO到MO
            self.convert_file()
            messagebox.showinfo("成功", f"MO文件已保存到: {self.mo_path.get()}")
        except Exception as e:
            messagebox.showerror("错误", f"转换失败: {str(e)}")
    
    def convert_file(self):
        """转换PO文件为MO文件"""
        po_file = self.po_path.get()
        mo_file = self.mo_path.get()
        
        if not po_file:
            messagebox.showwarning("警告", "请先选择PO文件")
            return
        
        if not mo_file:
            messagebox.showwarning("警告", "请指定MO文件输出路径")
            return
        
        try:
            # 确保目录存在
            os.makedirs(os.path.dirname(mo_file), exist_ok=True)
            
            # 使用gettext编译
            with open(po_file, 'rb') as f:
                po_data = gettext.GNUTranslations(f)
            
            with open(mo_file, 'wb') as f:
                po_data._catalog[''] = po_data._info
                po_data._catalog = {k: v for k, v in sorted(po_data._catalog.items())}
                gettext._wrap_write_mo(f, po_data._catalog)
            
            messagebox.showinfo("成功", f"文件转换成功: {mo_file}")
        except Exception as e:
            messagebox.showerror("错误", f"转换失败: {str(e)}")

def main():
    root = tk.Tk()
    app = POtoMOConverter(root)
    root.mainloop()

if __name__ == "__main__":
    main()
